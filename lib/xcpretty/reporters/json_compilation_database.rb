module XCPretty
  class JSONCompilationDatabase < Reporter

    FILEPATH = 'build/reports/compilation_db.json'

    def load_dependencies
      unless @@loaded ||= false
        require 'fileutils'
        require 'pathname'
        require 'json'
        @@loaded = true
      end
    end

    def initialize(options)
      super(options)
      @compilation_units = []
      @pch_path = nil
      @current_file = nil
      @current_path = nil
      @swift_compilation_compile_commands = {}
      @swift_compilation_unit_files = {}
    end

    def format_process_pch_command(file_path)
      @pch_path = file_path
    end

    def format_compile(file_name, file_path)
      @current_file = file_name
      @current_path = file_path
    end

    def format_compile_command(compiler_command, file_path)
      directory = file_path.gsub("#{@current_path}", '').gsub(/\/$/, '')
      directory = '/' if directory.empty?

      cmd = compiler_command
      cmd = cmd.gsub(/(\-include)\s.*\.pch/, "\\1 #{@pch_path}") if @pch_path

      @compilation_units << {command: cmd,
                             file: @current_path,
                             directory: directory}
    end

    def format_swift_compile_command(compiler_command, module_name)
      directory = '/'
      cmd = compiler_command
      cmd = cmd.gsub(/(\-include)\s.*\.pch/, "\\1 #{@pch_path}") if @pch_path
      @swift_compilation_compile_commands[module_name] = cmd
    end

    def format_swift_compile_file(compiler_command, module_name)
      swift_compilation_unit_file = @swift_compilation_unit_files[module_name]
      swift_compilation_unit_file = {} if swift_compilation_unit_file.nil?

      compiler_command.scan(/\s(\/.*?\.swift)\s/).each { |item|
        item.each { |file|
          unless swift_compilation_unit_file.has_key?(file)
            swift_compilation_unit_file[file] = 1
          end
        }
      }
      @swift_compilation_unit_files[module_name] = swift_compilation_unit_file
    end

    def write_report
      @swift_compilation_compile_commands.each { |module_name,cmd|
        swift_compilation_unit_file = @swift_compilation_unit_files[module_name]
        unless swift_compilation_unit_file.nil?
          swift_compilation_unit_file.each_key { |file|
            @compilation_units << {command: cmd,
              file: file,
              directory: '/'}
          }
        end
      }
      File.open(@filepath, 'w') do |f|
        f.write(@compilation_units.to_json)
      end
    end
  end
end

