import sys
import re

REG = {f"r{i}": i for i in range(16)}
REG.update({f"$r{i}": i for i in range(16)})
REG.update({"$acc": 0, "$base": 9, "$flags": 12, "$ra": 15})

OP = {
    "addi": 0x1,
    "lw":   0x2,
    "sw":   0x3,
    "beq":  0x4,
    "bne":  0x5,
    "j":    0x6,
    "jal":  0x7,
    "li":   0x8,
    "andi": 0x9,
    "ori":  0xA,
    "xori": 0xB,
    "slti": 0xC,
    "lui":  0xD,
    "jr":   0xE,
    "nop":  0xF,
}

FUNCT = {
    "and": 0x0, "or": 0x1, "add": 0x2, "nor": 0x3,
    "mflo": 0x4, "mfhi": 0x5, "sub": 0x6, "slt": 0x7,
    "xor": 0x8, "sll": 0x9, "srl": 0xA, "mul": 0xB,
    "passb": 0xC, "passa": 0xD, "not": 0xE, "neg": 0xF,
}

def clean(line):
    return line.split("#")[0].split("//")[0].strip()

def tok(line):
    return [x for x in re.split(r"[\s,]+", line) if x]

def num(x):
    return int(x, 0)

def reg(x):
    x = x.lower()
    if x not in REG:
        raise ValueError(f"bad register {x}")
    return REG[x]

def imm8(x):
    v = num(x)
    if not -128 <= v <= 255:
        raise ValueError(f"imm8 out of range {v}")
    return v & 0xFF

def addr12(x):
    v = num(x)
    if v % 2:
        raise ValueError("jump address must be even")
    return (v // 2) & 0xFFF

def encode(parts, labels, pc):
    op = parts[0].lower()

    if op == "nop":
        return OP["nop"] << 12

    if op in FUNCT:
        f = FUNCT[op]

        if op in ("mflo", "mfhi"):
            rs, rt = 0, 0
        elif op in ("not", "neg", "passa", "passb"):
            rs, rt = reg(parts[1]), 0
        else:
            rs, rt = reg(parts[1]), reg(parts[2])

        return (rt << 8) | (rs << 4) | f

    if op in ("addi", "li", "andi", "ori", "xori", "slti", "lui"):
        rd = reg(parts[1])
        im = imm8(parts[2])
        return (OP[op] << 12) | (rd << 8) | im

    if op in ("lw", "sw"):
        rd = reg(parts[1])
        im = mem_imm(parts[2])
        return (OP[op] << 12) | (rd << 8) | im

    if op in ("beq", "bne"):
        rd = reg(parts[1])
        target = parts[2]
        off = labels[target] - (pc + 1) if target in labels else num(target)
        return (OP[op] << 12) | (rd << 8) | (off & 0xFF)

    if op in ("j", "jal"):
        target = parts[1]
        a = labels[target] if target in labels else addr12(target)
        return (OP[op] << 12) | (a & 0xFFF)

    if op == "jr":
        rd = reg(parts[1])
        return (OP["jr"] << 12) | (rd << 8)

    raise ValueError(f"unknown instruction {op}")

def mem_imm(x):
    m = re.match(r"(-?(?:0x[0-9a-fA-F]+|\d+))\((.*?)\)$", x)
    if not m:
        return imm8(x)

    base = m.group(2).lower()
    if base not in ("r9", "$r9", "$base"):
        raise ValueError("base must be r9")

    return imm8(m.group(1))


def assemble(src, out):
    lines = open(src).readlines()

    labels = {}
    insts = []
    pc = 0

    for line in lines:
        line = clean(line)
        if not line:
            continue

        if ":" in line:
            label, rest = line.split(":", 1)
            labels[label.strip()] = pc
            line = rest.strip()
            if not line:
                continue

        insts.append((pc, line))
        pc += 1

    codes = []
    for pc, line in insts:
        parts = tok(line)
        codes.append(encode(parts, labels, pc))

    with open(out, "w") as f:
        for c in codes:
            f.write(f"{c:04X}\n")

if __name__ == "__main__":
    assemble(sys.argv[1], sys.argv[2])
