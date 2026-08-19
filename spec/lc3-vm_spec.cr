require "./spec_helper"

describe "sign_extend" do
  it "extends a negative 5-bit immediate to 16 bits" do
    sign_extend(0x1F_u16, 5).should eq(0xFFFF_u16) # -1
    sign_extend(0x10_u16, 5).should eq(0xFFF0_u16) # -16
  end

  it "leaves a positive immediate alone" do
    sign_extend(0x0F_u16, 5).should eq(0x000F_u16) # 15
  end

  it "extends a negative 9-bit PC offset" do
    sign_extend(0x1FF_u16, 9).should eq(0xFFFF_u16) # -1
  end
end

describe "memory" do
  it "addresses the whole 16-bit space, including 0xFFFF" do
    write_memory(0xFFFF_u16, 42_u16)
    read_memory(0xFFFF_u16).should eq(42_u16)
  end
end

describe "16-bit wraparound" do
  # The ISA truncates results to 16 bits, so these must wrap rather than raise.
  it "wraps the PC from 0xFFFF to 0x0000" do
    pc = Register::ProgramCounter.value
    REGISTER_STORAGE[pc] = 0xFFFF_u16
    REGISTER_STORAGE[pc] = REGISTER_STORAGE[pc] &+ 1
    REGISTER_STORAGE[pc].should eq(0x0000_u16)
  end

  it "adds a negative offset to a low address without raising" do
    (0x0002_u16 &+ sign_extend(0x1FF_u16, 9)).should eq(0x0001_u16)
  end
end

# dispatch() runs its own fetch loop, so the only way to exercise a decoded
# instruction is to run a real image. spec/fixtures/not-out.obj is five words:
#   LD R1, #3 / NOT R0, R1 / TRAP OUT / TRAP HALT / 0x00BE
# ~0x00BE = 0xFF41, so OUT must print (0xFF41 & 0xFF) = 0x41 = "A".
# NOT reading the wrong register prints U+FFFF instead, and OUT failing to mask
# to a byte prints the full codepoint rather than one character.
describe "NOT and TRAP OUT" do
  it "negates the source register and prints the low byte" do
    output = IO::Memory.new
    status = Process.run(
      "crystal",
      ["run", "--no-debug", "#{__DIR__}/../src/main.cr", "--", "#{__DIR__}/fixtures/not-out.obj"],
      output: output, error: Process::Redirect::Inherit
    )

    status.success?.should be_true
    output.to_s.should eq("AHALT")
  end
end
