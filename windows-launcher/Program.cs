using System.Diagnostics;
using System.Text.Json;
using System.Text.Json.Serialization;

var baseDirectory = AppContext.BaseDirectory;
var configPath = args.Length > 0 && !args[0].StartsWith("--", StringComparison.Ordinal)
    ? ResolvePath(args[0], Environment.CurrentDirectory)
    : Path.Combine(baseDirectory, "launcher-config.json");

if (!File.Exists(configPath))
{
    Console.Error.WriteLine($"Config not found: {configPath}");
    return 2;
}

var config = await LoadConfigAsync(configPath);
var configDirectory = Path.GetDirectoryName(configPath) ?? Environment.CurrentDirectory;

var adbPath = ResolvePath(config.AdbPath, configDirectory);
var apkPath = ResolvePath(config.ApkPath, configDirectory);

if (!File.Exists(adbPath))
{
    Console.Error.WriteLine($"ADB not found: {adbPath}");
    return 2;
}

if (!File.Exists(apkPath))
{
    Console.Error.WriteLine($"APK not found: {apkPath}");
    return 2;
}

var runner = new CommandRunner(config.CommandTimeoutSeconds);

if (!string.IsNullOrWhiteSpace(config.RuntimeExecutable))
{
    StartRuntime(config, configDirectory);
}

Console.WriteLine("Starting ADB server...");
await runner.RunAsync(adbPath, "start-server");

if (!string.IsNullOrWhiteSpace(config.AdbConnectEndpoint))
{
    Console.WriteLine($"Connecting ADB endpoint: {config.AdbConnectEndpoint}");
    await runner.RunAsync(adbPath, $"connect {config.AdbConnectEndpoint}", allowFailure: true);
}

Console.WriteLine("Waiting for Android runtime/device...");
await runner.RunAsync(adbPath, WithDevice(config, "wait-for-device"), timeoutSeconds: config.DeviceBootTimeoutSeconds);

await PrintConnectedDevicesAsync(runner, adbPath);

if (ShouldInstall(args, config))
{
    await EnsureInstalledAsync(runner, adbPath, apkPath, config);
}
else
{
    Console.WriteLine("APK install step skipped by configuration/arguments.");
}

var activity = string.IsNullOrWhiteSpace(config.ActivityName)
    ? await ResolveLauncherActivityAsync(runner, adbPath, config)
    : config.ActivityName;

Console.WriteLine($"Launching {config.PackageName}{(string.IsNullOrWhiteSpace(activity) ? string.Empty : "/" + activity)}...");
if (string.IsNullOrWhiteSpace(activity))
{
    await runner.RunAsync(adbPath, WithDevice(config, $"shell monkey -p {config.PackageName} -c android.intent.category.LAUNCHER 1"));
}
else
{
    await runner.RunAsync(adbPath, WithDevice(config, $"shell am start -n {config.PackageName}/{activity}"));
}

if (!string.IsNullOrWhiteSpace(config.KeymapFile))
{
    Console.WriteLine($"Keymap config: {ResolvePath(config.KeymapFile, configDirectory)}");
    Console.WriteLine("Apply this keymap in the selected emulator/runtime. Real-time gameplay should not rely on slow ADB tap injection.");
}

Console.WriteLine("Launch sequence completed.");
return 0;

static async Task<LauncherConfig> LoadConfigAsync(string path)
{
    await using var stream = File.OpenRead(path);
    var config = await JsonSerializer.DeserializeAsync<LauncherConfig>(stream, JsonOptions.Default);
    if (config is null)
    {
        throw new InvalidOperationException("Launcher config is empty or invalid.");
    }

    if (string.IsNullOrWhiteSpace(config.AdbPath))
    {
        throw new InvalidOperationException("Config field 'adbPath' is required.");
    }

    if (string.IsNullOrWhiteSpace(config.ApkPath))
    {
        throw new InvalidOperationException("Config field 'apkPath' is required.");
    }

    if (string.IsNullOrWhiteSpace(config.PackageName))
    {
        throw new InvalidOperationException("Config field 'packageName' is required.");
    }

    return config;
}

static string ResolvePath(string path, string baseDirectory)
{
    return PathResolver.Resolve(path, baseDirectory);
}

static void StartRuntime(LauncherConfig config, string configDirectory)
{
    var runtimePath = ResolvePath(config.RuntimeExecutable!, configDirectory);
    if (!File.Exists(runtimePath))
    {
        Console.Error.WriteLine($"Runtime executable not found: {runtimePath}");
        return;
    }

    Console.WriteLine($"Starting Android runtime: {runtimePath}");
    Process.Start(new ProcessStartInfo
    {
        FileName = runtimePath,
        Arguments = config.RuntimeArguments ?? string.Empty,
        WorkingDirectory = string.IsNullOrWhiteSpace(config.RuntimeWorkingDirectory)
            ? Path.GetDirectoryName(runtimePath) ?? configDirectory
            : ResolvePath(config.RuntimeWorkingDirectory, configDirectory),
        UseShellExecute = false
    });
}

static async Task PrintConnectedDevicesAsync(CommandRunner runner, string adbPath)
{
    var result = await runner.RunAsync(adbPath, "devices", allowFailure: true);
    Console.WriteLine(result.Stdout.Trim());
}

static bool ShouldInstall(string[] args, LauncherConfig config)
{
    if (args.Any(arg => string.Equals(arg, "--no-install", StringComparison.OrdinalIgnoreCase)))
    {
        return false;
    }

    if (args.Any(arg => string.Equals(arg, "--install", StringComparison.OrdinalIgnoreCase)))
    {
        return true;
    }

    return !string.Equals(config.InstallMode, "skip", StringComparison.OrdinalIgnoreCase);
}

static async Task EnsureInstalledAsync(CommandRunner runner, string adbPath, string apkPath, LauncherConfig config)
{
    var installed = await IsPackageInstalledAsync(runner, adbPath, config);
    var installMode = config.InstallMode ?? "ifMissing";

    if (installed && string.Equals(installMode, "ifMissing", StringComparison.OrdinalIgnoreCase))
    {
        Console.WriteLine($"Package already installed: {config.PackageName}");
        return;
    }

    Console.WriteLine($"Installing APK: {apkPath}");
    var flags = config.AllowDowngrade ? "-r -d" : "-r";
    await runner.RunAsync(adbPath, WithDevice(config, $"install {flags} \"{apkPath}\""), timeoutSeconds: config.InstallTimeoutSeconds);
}

static async Task<bool> IsPackageInstalledAsync(CommandRunner runner, string adbPath, LauncherConfig config)
{
    var result = await runner.RunAsync(adbPath, WithDevice(config, $"shell pm path {config.PackageName}"), allowFailure: true);
    return result.ExitCode == 0 && result.Stdout.Contains("package:", StringComparison.OrdinalIgnoreCase);
}

static async Task<string?> ResolveLauncherActivityAsync(CommandRunner runner, string adbPath, LauncherConfig config)
{
    var result = await runner.RunAsync(adbPath, WithDevice(config, $"shell cmd package resolve-activity --brief {config.PackageName}"), allowFailure: true);
    if (result.ExitCode != 0)
    {
        return null;
    }

    var lines = result.Stdout
        .Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
        .Where(line => line.Contains('/'))
        .ToArray();

    var component = lines.LastOrDefault();
    if (component is null)
    {
        return null;
    }

    var slashIndex = component.IndexOf('/');
    return slashIndex >= 0 && slashIndex + 1 < component.Length
        ? component[(slashIndex + 1)..]
        : null;
}

static string WithDevice(LauncherConfig config, string adbArguments)
{
    return string.IsNullOrWhiteSpace(config.DeviceSerial)
        ? adbArguments
        : $"-s {config.DeviceSerial} {adbArguments}";
}

sealed record LauncherConfig
{
    [JsonPropertyName("adbPath")]
    public string AdbPath { get; init; } = "..\\tools\\platform-tools\\adb.exe";

    [JsonPropertyName("apkPath")]
    public string ApkPath { get; init; } = "..\\2_3_4_player_mini_games_v5_8_2.apk";

    [JsonPropertyName("packageName")]
    public string PackageName { get; init; } = "com.ction.playergames";

    [JsonPropertyName("activityName")]
    public string? ActivityName { get; init; } = ".RunnerActivity";

    [JsonPropertyName("deviceSerial")]
    public string? DeviceSerial { get; init; }

    [JsonPropertyName("adbConnectEndpoint")]
    public string? AdbConnectEndpoint { get; init; }

    [JsonPropertyName("installMode")]
    public string InstallMode { get; init; } = "ifMissing";

    [JsonPropertyName("allowDowngrade")]
    public bool AllowDowngrade { get; init; }

    [JsonPropertyName("runtimeExecutable")]
    public string? RuntimeExecutable { get; init; }

    [JsonPropertyName("runtimeArguments")]
    public string? RuntimeArguments { get; init; }

    [JsonPropertyName("runtimeWorkingDirectory")]
    public string? RuntimeWorkingDirectory { get; init; }

    [JsonPropertyName("keymapFile")]
    public string? KeymapFile { get; init; } = "keymap.example.json";

    [JsonPropertyName("commandTimeoutSeconds")]
    public int CommandTimeoutSeconds { get; init; } = 60;

    [JsonPropertyName("deviceBootTimeoutSeconds")]
    public int DeviceBootTimeoutSeconds { get; init; } = 180;

    [JsonPropertyName("installTimeoutSeconds")]
    public int InstallTimeoutSeconds { get; init; } = 300;
}

static class PathResolver
{
    public static string Resolve(string path, string baseDirectory)
    {
        var expanded = Environment.ExpandEnvironmentVariables(path);
        if (Path.IsPathRooted(expanded))
        {
            return Path.GetFullPath(expanded);
        }

        var configRelative = Path.GetFullPath(Path.Combine(baseDirectory, expanded));
        if (File.Exists(configRelative) || Directory.Exists(configRelative))
        {
            return configRelative;
        }

        var workingDirectoryRelative = Path.GetFullPath(Path.Combine(Environment.CurrentDirectory, expanded));
        if (File.Exists(workingDirectoryRelative) || Directory.Exists(workingDirectoryRelative))
        {
            return workingDirectoryRelative;
        }

        return configRelative;
    }
}

sealed class CommandRunner(int defaultTimeoutSeconds)
{
    public async Task<CommandResult> RunAsync(string fileName, string arguments, int? timeoutSeconds = null, bool allowFailure = false)
    {
        using var process = new Process();
        process.StartInfo = new ProcessStartInfo
        {
            FileName = fileName,
            Arguments = arguments,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        process.Start();

        var stdoutTask = process.StandardOutput.ReadToEndAsync();
        var stderrTask = process.StandardError.ReadToEndAsync();
        var timeout = TimeSpan.FromSeconds(timeoutSeconds ?? defaultTimeoutSeconds);

        if (!await WaitForExitAsync(process, timeout))
        {
            TryKill(process);
            throw new TimeoutException($"Command timed out after {timeout.TotalSeconds:n0}s: {fileName} {arguments}");
        }

        var result = new CommandResult(process.ExitCode, await stdoutTask, await stderrTask);
        if (!allowFailure && result.ExitCode != 0)
        {
            throw new InvalidOperationException($"Command failed ({result.ExitCode}): {fileName} {arguments}{Environment.NewLine}{result.Stderr}");
        }

        if (!string.IsNullOrWhiteSpace(result.Stdout))
        {
            Console.WriteLine(result.Stdout.Trim());
        }

        if (!string.IsNullOrWhiteSpace(result.Stderr))
        {
            Console.Error.WriteLine(result.Stderr.Trim());
        }

        return result;
    }

    static async Task<bool> WaitForExitAsync(Process process, TimeSpan timeout)
    {
        using var cts = new CancellationTokenSource(timeout);
        try
        {
            await process.WaitForExitAsync(cts.Token);
            return true;
        }
        catch (OperationCanceledException)
        {
            return false;
        }
    }

    static void TryKill(Process process)
    {
        try
        {
            if (!process.HasExited)
            {
                process.Kill(entireProcessTree: true);
            }
        }
        catch
        {
            // Best-effort cleanup after timeout.
        }
    }
}

sealed record CommandResult(int ExitCode, string Stdout, string Stderr);

static class JsonOptions
{
    public static readonly JsonSerializerOptions Default = new()
    {
        ReadCommentHandling = JsonCommentHandling.Skip,
        AllowTrailingCommas = true,
        WriteIndented = true
    };
}
