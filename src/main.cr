require "./lc3-vm"

if ARGV.size == 0
  puts "lc3 [image-file1] ..."
  exit
end

filenames = ARGV
filenames.each { |filename| read_image_file(filename) }

stdin : Int32 = 0

# Set Termios
term : LibC::Termios = LibC::Termios.new

LibC.tcgetattr(stdin, pointerof(term))

term.c_iflag &= LibC::IGNBRK | LibC::BRKINT | LibC::PARMRK | LibC::ISTRIP | LibC::INLCR | LibC::IGNCR | LibC::ICRNL | LibC::IXON
term.c_lflag &= ~(LibC::ICANON | LibC::ECHO)

LibC.tcsetattr(stdin, LibC::TCSANOW, pointerof(term))

dispatch()

# Reset termios data
term.c_lflag = 0
LibC.tcsetattr(stdin, LibC::TCSANOW, pointerof(term))
