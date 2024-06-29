import sharp from 'sharp';
import 'promise.withresolvers/auto';

const keypress = async () => {
    const { resolve, _reject, promise } = Promise.withResolvers();

    process.stdin.setRawMode(true);
    process.stdin.once('data', () => {
        process.stdin.setRawMode(false);
        process.stdin.pause();
        resolve();
    });

    return promise;
};

const saveCursor = () => process.stdout.write('\x1b7');
const restoreCursor = () => process.stdout.write('\x1b8');
const setCursor = (row, col) => process.stdout.write(`\x1b[${row};${col}H`);
const clearDisplay = () => process.stdout.write('\x1b[2J');

const alternateBuffer = () => process.stdout.write('\x1b[?47h');
const normalBuffer = () => process.stdout.write('\x1b[?47l');

//const insertMode = () => process.stdout.write('\x1b[4h');
//const replaceMode = () => process.stdout.write('\x1b[4l');

//const autoNewline = () => process.stdout.write('\x1b[20h');
//const normalNewline = () => process.stdout.write('\x1b[20l');

const hideCursor = () => process.stdout.write('\x1b[?25l');
const showCursor = () => process.stdout.write('\x1b[?25h');

const setForeground = (r, g, b) => process.stdout.write(`\x1b[38;2;${r};${g};${b}m`);
const setBackground = (r, g, b) => process.stdout.write(`\x1b[48;2;${r};${g};${b}m`);
const resetColor = () => process.stdout.write('\x1b[0m');

class Frame {
    constructor(cols, rows, data) {
        this.cols = cols;
        this.rows = rows;
        this.data = data;
    }

    static CBL = 2;
    static RBL = 4;

    display() {
        // TODO handle images with size not divisible by CBL, RBL
        const cblocks = Math.ceil(this.cols / Frame.CBL);
        const rblocks = Math.ceil(this.rows / Frame.RBL);

        for (let r = 0; r < rblocks; r++) {
            for (let c = 0; c < cblocks; c++) {
                const pixels = this.getBlockPixels(c, r);
                const { char, foreground, background } = this.getBlockChar(pixels);

                setCursor(r + 1, c + 1);

                setForeground(foreground.r, foreground.g, foreground.b);
                setBackground(background.r, background.g, background.b);

                process.stdout.write(char);

                resetColor();
            }
        }
    }

    calcIndex(bc, br, dc, dr) {
        return 3 * ((br * Frame.RBL + dr) * this.cols + (bc * Frame.CBL + dc));
    }

    getPixel(bc, br, dc, dr) {
        const index = this.calcIndex(bc, br, dc, dr);
        return { r: this.data[index + 0] ?? 0, g: this.data[index + 1] ?? 0, b: this.data[index + 2] ?? 0 };
    }

    getBlockPixels(c, r) {
        const res = [];
        for (let dr = 0; dr < Frame.RBL; dr++) {
            for (let dc = 0; dc < Frame.CBL; dc++) {
                res.push(this.getPixel(c, r, dc, dr));
            }
        }
        return res;
    }

    // octants (2×4 mosaics) U+1CD00 - U+1CDE5
    // + U+1FBE6 and U+1FBE7 two new quadrants
    // https://gist.github.com/Explorer09/1da382e4b1cf3bf2e8009e60836af70b
    // http://www.unicode.org/L2/L2021/21235-terminals-supplement.pdf

    static BLOCKS_4x2 = [
        ' ', '𜺨', '𜺫', '🮂', '𜴀', '▘', '𜴁', '𜴂', '𜴃', '𜴄', '▝', '𜴅', '𜴆', '𜴇', '𜴈', '▀',
        '𜴉', '𜴊', '𜴋', '𜴌', '🯦', '𜴍', '𜴎', '𜴏', '𜴐', '𜴑', '𜴒', '𜴓', '𜴔', '𜴕', '𜴖', '𜴗',
        '𜴘', '𜴙', '𜴚', '𜴛', '𜴜', '𜴝', '𜴞', '𜴟', '🯧', '𜴠', '𜴡', '𜴢', '𜴣', '𜴤', '𜴥', '𜴦',
        '𜴧', '𜴨', '𜴩', '𜴪', '𜴫', '𜴬', '𜴭', '𜴮', '𜴯', '𜴰', '𜴱', '𜴲', '𜴳', '𜴴', '𜴵', '🮅',
        '𜺣', '𜴶', '𜴷', '𜴸', '𜴹', '𜴺', '𜴻', '𜴼', '𜴽', '𜴾', '𜴿', '𜵀', '𜵁', '𜵂', '𜵃', '𜵄',
        '▖', '𜵅', '𜵆', '𜵇', '𜵈', '▌', '𜵉', '𜵊', '𜵋', '𜵌', '▞', '𜵍', '𜵎', '𜵏', '𜵐', '▛',
        '𜵑', '𜵒', '𜵓', '𜵔', '𜵕', '𜵖', '𜵗', '𜵘', '𜵙', '𜵚', '𜵛', '𜵜', '𜵝', '𜵞', '𜵟', '𜵠',
        '𜵡', '𜵢', '𜵣', '𜵤', '𜵥', '𜵦', '𜵧', '𜵨', '𜵩', '𜵪', '𜵫', '𜵬', '𜵭', '𜵮', '𜵯', '𜵰',
        '𜺠', '𜵱', '𜵲', '𜵳', '𜵴', '𜵵', '𜵶', '𜵷', '𜵸', '𜵹', '𜵺', '𜵻', '𜵼', '𜵽', '𜵾', '𜵿',
        '𜶀', '𜶁', '𜶂', '𜶃', '𜶄', '𜶅', '𜶆', '𜶇', '𜶈', '𜶉', '𜶊', '𜶋', '𜶌', '𜶍', '𜶎', '𜶏',
        '▗', '𜶐', '𜶑', '𜶒', '𜶓', '▚', '𜶔', '𜶕', '𜶖', '𜶗', '▐', '𜶘', '𜶙', '𜶚', '𜶛', '▜',
        '𜶜', '𜶝', '𜶞', '𜶟', '𜶠', '𜶡', '𜶢', '𜶣', '𜶤', '𜶥', '𜶦', '𜶧', '𜶨', '𜶩', '𜶪', '𜶫',
        '▂', '𜶬', '𜶭', '𜶮', '𜶯', '𜶰', '𜶱', '𜶲', '𜶳', '𜶴', '𜶵', '𜶶', '𜶷', '𜶸', '𜶹', '𜶺',
        '𜶻', '𜶼', '𜶽', '𜶾', '𜶿', '𜷀', '𜷁', '𜷂', '𜷃', '𜷄', '𜷅', '𜷆', '𜷇', '𜷈', '𜷉', '𜷊',
        '𜷋', '𜷌', '𜷍', '𜷎', '𜷏', '𜷐', '𜷑', '𜷒', '𜷓', '𜷔', '𜷕', '𜷖', '𜷗', '𜷘', '𜷙', '𜷚',
        '▄', '𜷛', '𜷜', '𜷝', '𜷞', '▙', '𜷟', '𜷠', '𜷡', '𜷢', '▟', '𜷣', '▆', '𜷤', '𜷥', '█'
    ];

    getBlockChar(pixels) {
        const vals = [];
        for (const { r, g, b } of pixels) {
            vals.push((r + g + b >= (3 * 0xc0)) ? 1 : 0);
        }

        return {
            char: Frame.BLOCKS_4x2[Number.parseInt(vals.reverse().join(''), 2)],
            foreground: { r: 0xff, g: 0xff, b: 0xff },
            background: { r: 0x00, g: 0x00, b: 0x00 }
        };
    }
}

const main = async () => {
    const cols = 320, rows = 200;

    const image = await sharp('sammy.png')
        .resize(cols, rows, { fit: 'inside' })
        .toColorspace('srgb');
    //await image.toFile('delme.png');
    const buffer = await image.raw().toBuffer({ resolveWithObject: true });

    const frame = new Frame(buffer.info.width, buffer.info.height, buffer.data);

    hideCursor();
    saveCursor();
    alternateBuffer();
    clearDisplay();

    frame.display();

    await keypress();

    normalBuffer();
    restoreCursor();
    showCursor();
};

await main();
