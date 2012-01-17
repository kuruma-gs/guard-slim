require 'guard/guard'
require 'guard/watcher'
require 'slim'
require 'fileutils'

module Guard
  class Slim < Guard
    ALL      = File.join '**', '*'
    Template = ::Slim::Template

    def initialize(watchers = [], options = {})
      @output_root  = options.delete(:output_root) || Dir.getwd
      @input_root   = options.delete(:input_root) || Dir.getwd
      @context      = options.delete(:context) || Object.new
      @slim         = options.delete(:slim) || {}
      @all_on_start = options.delete(:all_on_start) || true

      super watchers, options
    end

    def start
      UI.info 'Guard-Slim: Waiting for changes...'
      run_all if @all_on_start
    end

    def run_all
      run_on_change all_paths
    end
    def run_on_change(paths)
      paths.each do |path|
        content = render File.read(path)
        open(build_path(path), 'w') do |file|
          @slim[:pretty] ?
            file.puts(content) :
            file.write(content)
        end
        UI.info "Guard-Slim: Rendered #{ path } to #{ build_path path }"
      end
    end

    protected

      def build_path(path)
        path     = File.expand_path(path).sub @input_root, @output_root
        dirname  = File.dirname path

        FileUtils.mkpath dirname unless File.directory? dirname

        basename = File.basename path, '.slim'
        basename << '.html' if File.extname(basename).empty?

        File.join dirname, basename
      end

      def render(source)
        Template.new( @slim ) { source }.render @context
      rescue => e
        UI.info "Guard-Slim: ERROR"
        UI.info "-----------------------"
        UI.info e
        UI.info "-----------------------"
        "<pre class='error'>#{e}</pre>"
      end

      def all_paths
        Watcher.match_files self, Dir[ ALL ]
      end

  end
end
