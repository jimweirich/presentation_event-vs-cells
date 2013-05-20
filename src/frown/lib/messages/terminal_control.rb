
class TerminalControl
  def clear_screen
    goto_home
    print "\x1b[0J"
  end

  def clear_line
    print "\x1b[K"
  end

  def goto_home
    print "\x1b[1;1f"
  end

  def goto(row, col)
    print "\x1b[#{row};#{col}f"
  end
end
