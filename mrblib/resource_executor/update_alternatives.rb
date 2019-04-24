module ::MItamae
  module Plugin
    module ResourceExecutor
      class UpdateAlternatives < ::MItamae::ResourceExecutor::Base
        #
        # 状態
        # - エントリがあり、パスも登録されてあり、現在のリンクがパスと同一
        #
        def apply
          if current.exists && desired.exists then
            MItamae.logger.debug "Do Nothing: #{attributes.name}"
          elsif !current.exists && desired.exists then
            MItamae.logger.debug "Install: #{attributes.name}"
          elsif current.exists && !desired.exists then
            MItamae.logger.debug "Remove: #{attributes.name}"
          elsif !current.exists && !desired.exists then
            MItamae.logger.debug "Do Nothing: #{attributes.name}"
          end
        end

        private

        def set_current_attributes(current, action)
          result = run_command(['update-alternatives', '--query', attributes.name], error: false)
          current.exists = result.success?
          return if result.failure?

          state = parse_alternatives(result)
          MItamae.logger.debug "#{state}"
        end

        def set_desired_attributes(desired, action)
          case action
          when :install
            desired.exists = true
          when :remove
            desired.exists = false
          end
        end

        def parse_alternatives(result)
          state = {
            :name => '',
            :link => '',
            :auto => false,
            :best => '',
            :value => '',
            :slave => {},
            :entry => {},
          }

          isSlave = false
          isEntry = false
          currentEntry = ''
          result.stdout.each_line {|raw|
            line = raw.chomp.strip
            case line
            when /^Name: ([\+\/\w-]+)$/
              state[:name] = $1
            when /^Link: ([\+\/\w-]+)$/
              state[:link] = $1
            when /^Status: (auto|manual)$/
              isSlave = false
              case $1
              when 'auto'
                state[:auto] = true
              when 'manual'
                state[:auto] = false
              end
            when /^Best: ([\/\+\.\w-]+)$/
              state[:best] = $1
            when /^Value: ([\/\+\.\w-]+)$/
              state[:value] = $1
            when /^Priority: (\d+)$/
              state[:entry][currentEntry][:priority] = $1
            when /^Slaves:/
              isSlave = true
            when /^Alternative: ([\/\+\.\w-]+)$/
              isSlave = false
              isEntry = true
              currentEntry = $1
              state[:entry][currentEntry] = {
                :priority => 0,
                :slave => {},
              }
            when ''
              next
            else
              if isSlave then
                data = line.split(' ')
                if isEntry then
                  state[:entry][currentEntry][:slave][data[0]] = data[1]
                else
                  state[:slave][data[0]] = data[1]
                end
              else
                raise "malformed line: '#{line.inspect}'"
              end
            end
          }

          return state
        end
      end
    end
  end
end
