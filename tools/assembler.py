import sys
import re

# =======================================================
# 16-bit CPU Assembler
#
# Instruction formats:
#
# R-Type:
#   [15:12] opcode = 0
#   [11:8]  rt
#   [7:4]   rs
#   [3:0]   funct
#
#   Your datapath writes R-type result into R0 accumulator.
#   Example:
#       add r1, r2        -> R0 = R1 + R2
#       add r0, r1, r2    -> R0 = R1 + R2
#
# I-Type:
#   [15:12] opcode
#   [11:8]  rd/rt
#   [7:0]   imm8
#
#   Example:
#       addi r1, 5
#       lw   r3, 0
#       sw   r0, 0
#       beq  r4, label
#
# J-Type:
#   [15:12] opcode
#   [11:0]  addr12
#
#   Example:
#       j halt
# =======================================================

REGISTERS = {
    "r0": 0,
    "r1": 1,
    "r2": 2,
    "r3": 3,
    "r4": 4,
    "r5": 5,
    "r6": 6,
    "r7": 7,
    "r8": 8,
    "r9": 9,
    "r10": 10,
    "r11": 11,
    "r12": 12,
    "r13": 13,
    "r14": 14,
    "r15": 15,

    "$r0": 0,
    "$r1": 1,
    "$r2": 2,
    "$r3": 3,
    "$r4": 4,
    "$r5": 5,
    "$r6": 6,
    "$r7": 7,
    "$r8": 8,
    "$r9": 9,
    "$r10": 10,
    "$r11": 11,
    "$r12": 12,
    "$r13": 13,
    "$r14": 14,
    "$r15": 15,

    # useful aliases for your CPU
    "$acc": 0,
    "$base": 9,
    "$flags": 12,
    "$ra": 15,
}

OP_RTYPE = 0x0
OP_ADDI  = 0x1
OP_LW    = 0x2
OP_SW    = 0x3
OP_BEQ   = 0x4
OP_BNE   = 0x5
OP_J     = 0x6
OP_JAL   = 0x7

FUNCTS = {
    "and":  0x0,
    "or":   0x1,
    "add":  0x2,
    "nor":  0x3,
    "mflo": 0x4,
    "mfhi": 0x5,
    "sub":  0x6,
    "slt":  0x7,
    "xor":  0x8,
    "sll":  0x9,
    "srl":  0xA,
    "mul":  0xB,
}

I_TYPE_OPS = {
    "addi": OP_ADDI,
    "lw":   OP_LW,
    "sw":   OP_SW,
    "beq":  OP_BEQ,
    "bne":  OP_BNE,
}

J_TYPE_OPS = {
    "j":   OP_J,
    "jal": OP_JAL,
}


def strip_comment(line: str) -> str:
    # support both # comments and // comments
    line = line.split("#")[0]
    line = line.split("//")[0]
    return line.strip()


def tokenize(line: str):
    # split by spaces, commas, tabs
    return [p.strip() for p in re.split(r"[\s,]+", line) if p.strip()]


def get_reg(token: str) -> int:
    token = token.lower()

    if token in REGISTERS:
        return REGISTERS[token]

    # allow r3 style
    if token.startswith("r") and token[1:].isdigit():
        n = int(token[1:])
        if 0 <= n <= 15:
            return n

    # allow $3 style
    if token.startswith("$") and token[1:].isdigit():
        n = int(token[1:])
        if 0 <= n <= 15:
            return n

    # allow plain 3 style
    if token.isdigit():
        n = int(token)
        if 0 <= n <= 15:
            return n

    raise ValueError(f"Invalid register: {token}")


def parse_int(token: str) -> int:
    return int(token, 0)


def check_imm8(value: int) -> int:
    if not -128 <= value <= 255:
        raise ValueError(f"imm8 out of range: {value}")

    return value & 0xFF


def check_addr12(value: int) -> int:
    if not 0 <= value <= 0xFFF:
        raise ValueError(f"addr12 out of range: {value}")

    return value & 0xFFF


def encode_r_type(op: str, parts):
    funct = FUNCTS[op]

    # Two accepted syntaxes:
    #
    #   add r1, r2
    #       means R0 = R1 + R2
    #
    #   add r0, r1, r2
    #       also means R0 = R1 + R2
    #       destination must be R0 because your datapath writes R-type to accumulator

    if len(parts) == 3:
        rs = get_reg(parts[1])
        rt = get_reg(parts[2])

    elif len(parts) == 4:
        rd = get_reg(parts[1])
        if rd != 0:
            raise ValueError(
                f"{op} destination must be r0 in this CPU, because R-type writes to accumulator"
            )
        rs = get_reg(parts[2])
        rt = get_reg(parts[3])

    else:
        raise ValueError(f"Bad R-type syntax: {' '.join(parts)}")

    code = (OP_RTYPE << 12) | (rt << 8) | (rs << 4) | funct
    return code


def encode_i_type(op: str, parts, labels, pc):
    opcode = I_TYPE_OPS[op]

    if op == "addi":
        # addi rd, imm8
        if len(parts) != 3:
            raise ValueError("Syntax: addi rd, imm8")

        rd = get_reg(parts[1])
        imm = check_imm8(parse_int(parts[2]))

        code = (opcode << 12) | (rd << 8) | imm
        return code

    elif op in ["lw", "sw"]:
        # Your ISA:
        #   lw rd, imm8
        #       R[rd] = MEM[R9 + signext(imm8)]
        #
        #   sw rt, imm8
        #       MEM[R9 + signext(imm8)] = R[rt]
        #
        # Also support lw r3, 0(r9), but base must be r9.

        if len(parts) != 3:
            raise ValueError(f"Syntax: {op} reg, imm8")

        reg = get_reg(parts[1])

        mem_operand = parts[2]

        match = re.match(r"(-?(?:0x[0-9a-fA-F]+|\d+))\((.*?)\)", mem_operand)
        if match:
            imm = parse_int(match.group(1))
            base = get_reg(match.group(2))

            if base != 9:
                raise ValueError(f"{op} base register must be r9 for this CPU")

        else:
            imm = parse_int(mem_operand)

        imm = check_imm8(imm)

        code = (opcode << 12) | (reg << 8) | imm
        return code

    elif op in ["beq", "bne"]:
        # Your datapath compares:
        #   R0 with R[reg]
        #
        # Syntax:
        #   beq r4, label
        #   bne r4, label
        #
        # Immediate is instruction offset:
        #   target = PC + 2 + (imm8 << 1)
        #
        # Since pc here is instruction index:
        #   imm = label_index - (pc + 1)

        if len(parts) != 3:
            raise ValueError(f"Syntax: {op} reg, label_or_offset")

        reg = get_reg(parts[1])
        target = parts[2]

        if target in labels:
            imm = labels[target] - (pc + 1)
        else:
            imm = parse_int(target)

        imm = check_imm8(imm)

        code = (opcode << 12) | (reg << 8) | imm
        return code

    else:
        raise ValueError(f"Unknown I-type op: {op}")


def encode_j_type(op: str, parts, labels):
    opcode = J_TYPE_OPS[op]

    if len(parts) != 2:
        raise ValueError(f"Syntax: {op} label_or_addr")

    target = parts[1]

    if target in labels:
        addr = labels[target]
    else:
        # If user writes j 0x10, treat as byte address and convert to word index.
        # If user writes j 8, that also becomes word index 4.
        #
        # For your raw machine code, J 0x10 should be 6008.
        raw = parse_int(target)

        if raw % 2 != 0:
            raise ValueError("Jump byte address must be even")

        addr = raw // 2

    addr = check_addr12(addr)

    code = (opcode << 12) | addr
    return code


def assemble(asm_file, output_file):
    with open(asm_file, "r") as f:
        lines = f.readlines()

    labels = {}
    instructions = []

    # =======================================================
    # Pass 1: collect labels
    # =======================================================
    pc = 0  # instruction index, not byte address

    for line in lines:
        line = strip_comment(line)

        if not line:
            continue

        if line.startswith(".org"):
            # .org is byte address for your CPU
            # Example: .org 0x10 means instruction index 0x08
            parts = tokenize(line)
            if len(parts) != 2:
                raise ValueError("Syntax: .org address")

            target_pc = parse_int(parts[1]) // 2

            while pc < target_pc:
                instructions.append((pc, "nop"))
                pc += 1

            continue

        if ":" in line:
            label, rest = line.split(":", 1)
            label = label.strip()

            if not label:
                raise ValueError("Empty label")

            labels[label] = pc

            rest = rest.strip()
            if rest:
                instructions.append((pc, rest))
                pc += 1

        else:
            instructions.append((pc, line))
            pc += 1

    # =======================================================
    # Pass 2: encode instructions
    # =======================================================
    machine_code = []

    for pc, inst in instructions:
        parts = tokenize(inst)

        if not parts:
            continue

        op = parts[0].lower()

        if op == "nop":
            # harmless R-type AND R0,R0 style
            code = 0x0000

        elif op in FUNCTS:
            code = encode_r_type(op, parts)

        elif op in I_TYPE_OPS:
            code = encode_i_type(op, parts, labels, pc)

        elif op in J_TYPE_OPS:
            code = encode_j_type(op, parts, labels)

        else:
            raise ValueError(f"Unknown op at instruction {pc}: {op}")

        machine_code.append(f"{code:04X}")

    with open(output_file, "w") as f:
        for code in machine_code:
            f.write(code + "\n")

    print(f"Compiled {len(machine_code)} instructions to {output_file}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python assembler.py <input.asm> <output_program>")
        sys.exit(1)

    assemble(sys.argv[1], sys.argv[2])
