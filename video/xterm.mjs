Promise.withResolvers || (Promise.withResolvers = function withResolvers() {
    let a, b, c = new this(function (resolve, reject) { a = resolve; b = reject; });
    return { resolve: a, reject: b, promise: c };
});

const keypress = async () => {
    const { resolve, _reject, promise } = Promise.withResolvers();

    process.stdin.setRawMode(true);
    process.stdin.once('data', key => {
        process.stdin.setRawMode(false);
        process.stdin.pause();
        resolve();
    });

    return promise;
};

// ▀ ▄ █ ▌ ▐ ▖ ▗ ▘ ▙ ▚ ▛ ▜ ▝ ▞ ▟

const saveCursor = () => process.stdout.write('\x1b7');
const restoreCursor = () => process.stdout.write('\x1b8');
const setCursor = (row, col) => process.stdout.write(`\x1b[${row};${col}H`);
const clearDisplay = () => process.stdout.write('\x1b[2J');

const alternateBuffer = () => process.stdout.write('\x1b[?47h');
const normalBuffer = () => process.stdout.write('\x1b[?47l');

const insertMode = () => process.stdout.write('\x1b[4h');
const replaceMode = () => process.stdout.write('\x1b[4l');

const autoNewline = () => process.stdout.write('\x1b[20h');
const normalNewline = () => process.stdout.write('\x1b[20l');

const main = async () => {
    saveCursor();
    alternateBuffer();
    //clearDisplay();

    setCursor(5, 80);

    process.stdout.write("\x1b[31;1;4mHello\x1b[0m");

    await keypress();

    normalBuffer();
    restoreCursor();
};

await main();
