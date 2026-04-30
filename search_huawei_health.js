const fs = require('fs');
const path = require('path');

const root = process.argv[2];
if (!root) {
  console.error('Usage: node search_huawei_health.js <root>');
  process.exit(1);
}

const patterns = [
  /BluetoothGatt/,
  /BluetoothLeScanner/,
  /BluetoothGattCallback/,
  /ScanCallback/,
  /CompanionDeviceManager/,
  /AssociationRequest/,
  /discoverServices/,
  /writeCharacteristic/,
  /readCharacteristic/,
  /setCharacteristicNotification/,
  /onServicesDiscovered/,
  /onCharacteristicChanged/,
  /onConnectionStateChange/,
  /REQUEST_COMPANION_PROFILE_WATCH/,
  /associate/,
];

function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full, out);
    } else if (entry.isFile() && full.endsWith('.smali')) {
      out.push(full);
    }
  }
  return out;
}

const files = walk(root);
let count = 0;

for (const file of files) {
  const text = fs.readFileSync(file, 'utf8');
  const lines = text.split(/\r?\n/);
  let matched = false;
  for (let i = 0; i < lines.length; i++) {
    if (patterns.some((p) => p.test(lines[i]))) {
      if (!matched) {
        console.log(`FILE ${file}`);
        matched = true;
        count++;
      }
      console.log(`${i + 1}: ${lines[i]}`);
    }
  }
}

console.error(`Matched files: ${count}`);
