using System.Collections.Concurrent;
using Windows.Devices.Bluetooth.Advertisement;

var watcher = new BluetoothLEAdvertisementWatcher
{
    ScanningMode = BluetoothLEScanningMode.Active
};

var seen = new ConcurrentDictionary<ulong, (string Name, short Rssi)>();

watcher.Received += (_, args) =>
{
    var name = args.Advertisement.LocalName ?? string.Empty;
    seen[args.BluetoothAddress] = (name, args.RawSignalStrengthInDBm);
};

watcher.Start();
await Task.Delay(TimeSpan.FromSeconds(10));
watcher.Stop();

foreach (var item in seen.OrderBy(x => x.Key).Take(100))
{
    Console.WriteLine($"{item.Key:X12}	{item.Value.Rssi}	{item.Value.Name}");
}
