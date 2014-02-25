class Analyser
  def initialize(logdir)
    @logdir = logdir
    @info = {}
  end

  def analyselogs
    log_dir = Dir.open(@logdir)

    puts "Processing #{log_dir.entries.size-2} log files"

    log_dir.entries.sort.drop(2).each do |log|
      puts "Analysing #{@logdir}/#{log}"
      contents = File.read("#{@logdir}/#{log}")
      tokens = contents.split
      parse(tokens)
    end

    print_stats
  end

  def parse(tokens)
    Parser.new(tokens, @info).parse
  end

  def print_stats
    puts 'statistics'
    keys = @info.keys.sort
    keys.each do |key|
      value = @info[key]
      puts "#{key} request count = #{value.count}"
      puts "average request duration: #{value.total_duration/value.count}"
      puts "average view duration: #{value.total_view_duration/value.count}"
    end
  end
end

class RInfo
  attr_accessor :total_duration, :total_view_duration, :count

  def initialize
    @count = 0
    @total_duration = 0
    @total_view_duration = 0
  end
end

class Parser
  def initialize(tokens = [], info = {})
    @info = info
    @tokens = tokens
    @duration = 0
    @view_duration = 0
    @controller = ''
    @action = ''
  end

  def parse
    state = 0
    @tokens.each do |token|
      case token
      when 'Processing' then
        state = 1 if state == 0
      when 'by' then
        state = 2 if state == 1
      when 'Completed' then
        state = 4 if state == 3
      when 'in' then
        state = 6 if state == 5
      when '(Views:' then
        state = 8 if state == 7
      else
        state = extract_token(token, state)
      end
    end
  end

  private

  def extract_token(token, state)
    if state == 2
      @contoller, @action = extract_controller_action(token)
      state = 3
    elsif state == 4
      @status = extract_status(token)
      state = 5
    elsif state == 6
      @duration = extract_duration(token)
      state = 7
    elsif state == 8
      @view_duration = extract_view_duration(token)
      state = 0
      finish_parse_block
      clear_attr
    end

    state
  end

  def finish_parse_block
    info = @info["#{@contoller}##{@action}"] || RInfo.new
    info.total_duration += @duration
    info.total_view_duration += @view_duration
    info.count += 1
    @info["#{@contoller}##{@action}"] = info
  end

  def clear_attr
    @duration = 0
    @view_duration = 0
    @action = ''
    @contoller = ''
  end

  def extract_controller_action(token)
    token.split('#')
  end

  def extract_status(token)
    token.to_i
  end

  def extract_duration(token)
    token.to_i
  end

  def extract_view_duration(token)
    token.to_i
  end
end


Analyser.new('data').analyselogs