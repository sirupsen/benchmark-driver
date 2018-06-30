require 'forwardable'

module BenchmarkDriver
  # BenchmarkDriver::Runner::* --> BenchmarkDriver::Output --> BenchmarkDriver::Output::*
  #
  # This is interface between runner plugin and output plugin, so that they can be loosely
  # coupled and to simplify implementation of both runner and output.
  #
  # Runner should call its interface in the following manner:
  #   with_warmup
  #     with_job(name:)
  #       with_context
  #         report
  #   with_benchmark
  #     with_job(name:)
  #       with_context
  #         report
  class Output
    require 'benchmark_driver/output/compare'
    require 'benchmark_driver/output/markdown'
    require 'benchmark_driver/output/record'
    require 'benchmark_driver/output/simple'

    extend Forwardable

    # BenchmarkDriver::Output is pluggable.
    # Create `BenchmarkDriver::Output::Foo` as benchmark_dirver-output-foo.gem and specify `-o foo`.
    #
    # @param [String] type
    def initialize(type:, jobs:, executables:)
      if type.include?(':')
        raise ArgumentError.new("Output type '#{type}' cannot contain ':'")
      end

      require "benchmark_driver/output/#{type}" # for plugin
      camelized = type.split('_').map(&:capitalize).join

      @output = ::BenchmarkDriver::Output.const_get(camelized, false).new(
        jobs: jobs,
        executables: executables,
      )
    end

    def_delegators :@output, :metrics_type=, :with_warmup, :with_benchmark, :with_job, :report

    def with_context(name:, executable:, &block)
      context = BenchmarkDriver::Context.new(name: name, executable: executable)
      @output.with_context(context) do
        block.call
      end
    end
  end
end
