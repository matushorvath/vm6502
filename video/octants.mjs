process.stdout.write('\x1b[93;100m');

//\x1b[38;2;${c24[f].map(x => x.toString()).join(';')};48;2;${c24[b].map(x => x.toString()).join(';')}m

for (let i = 0x00; i < 0xe5; i++) {
    process.stdout.write(String.fromCodePoint(0x1CD00 + i) + '█');
}

process.stdout.write('\x1b[0m');
