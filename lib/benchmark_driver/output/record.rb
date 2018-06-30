class BenchmarkDriver::Output::Record
  # @param [BenchmarkDriver::Metrics::Type] metrics_type
  attr_writer :metrics_type

  # @param [Array<String>] jobs
  # @param [Array<BenchmarkDriver::Config::Executable>] executables
  def initialize(jobs:, executables:)
    @executables = executables
    @job_warmup_context_metrics = Hash.new do |h1, k1|
      h1[k1] = Hash.new do |h2, k2|
        h2[k2] = Hash.new do |h3, k3|
          h3[k3] = []
        end
      end
    end
  end

  def with_warmup(&block)
    $stdout.print 'warming up'
    block.call
  ensure
    $stdout.puts
  end

  def with_benchmark(&block)
    @with_benchmark = true
    $stdout.print 'benchmarking'
    block.call
  ensure
    $stdout.puts
    @with_benchmark = false
    save_record
  end

  # @param [String] name
  def with_job(name:, &block)
    @job = name
    block.call
  end

  # @param [BenchmarkDriver::Context] context
  def with_context(context, &block)
    @context = context
    block.call
  end

  # @param [BenchmarkDriver::Metric] metric
  def report(metric)
    $stdout.print '.'
    @job_warmup_context_metrics[@job][!@with_benchmark][@context] << metric
  end

  private

  def save_record
    jobs = @benchmark_metrics
    yaml = {
      'type' => 'recorded',
      'job_warmup_context_metrics' => @job_warmup_context_metrics,
      'metrics_type' => @metrics_type,
    }.to_yaml
    File.write('benchmark_driver.record.yml', yaml)
  end
end
