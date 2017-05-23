require 'spec_helper'
require 'ssh_scan_api/job_queue'

describe SSHScan::JobQueue do
  it "should have zero requests to start with" do
    job_queue = SSHScan::JobQueue.new
    expect(job_queue.size).to eql(0)
  end

  it "should add jobs to the queue" do
    job_queue = SSHScan::JobQueue.new
    expect(job_queue.size).to eql(0)
    job_queue.add("job")
    expect(job_queue.size).to eql(1)
  end

  it "should pull jobs to the queue, in the right order" do
    job_queue = SSHScan::JobQueue.new
    expect(job_queue.size).to eql(0)
    job_queue.add("job1")
    job_queue.add("job2")
    expect(job_queue.next).to eql("job1")
    expect(job_queue.next).to eql("job2")
  end

  it "should be enumerable" do
    job_queue = SSHScan::JobQueue.new
    expect(job_queue.size).to eql(0)
    job_queue.add("job1")
    job_queue.add("job2")
    expect(job_queue).to respond_to(:each)
  end
end
