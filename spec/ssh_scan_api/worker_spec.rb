require 'spec_helper'
require 'ssh_scan_api/worker'
require 'ssh_scan'
require 'json'

describe SSHScan::Worker do

  before do :each  
    @worker = SSHScan::Worker.new
    @worker.set_environment("test")

    # Start fresh with a new database every time
    SSHScan::Scan.destroy_all
  end

  it "should have sane default behavior" do
    expect(@worker.instance_variable_get(:@worker_id)).to match(/^[\w]+{8}-[\w]+{4}-[\w]+{4}-[\w]+{4}-[\w]+{12}$/)
    expect(@worker.instance_variable_get(:@fingerprint_database_path)).to be_kind_of(::String)
    expect(@worker.instance_variable_get(:@policy_path)).to be_kind_of(::String)
    expect(@worker.instance_variable_get(:@poll_interval)).to eql(1)
  end

  it "should pull items off the queue and complete them" do
    # Manually add a scan to the queue
    scan = SSHScan::Scan.new do |s|
      s.scan_id = SecureRandom.uuid
      s.creation_time = Time.now
      s.target = "sshscan.rubidus.com"
      s.port = 22
      s.state = "QUEUED"
      s.save
    end

    # Verify the scan is in the queue
    scan_from_queue = SSHScan::Scan.find_by("scan_id": scan.scan_id)
    expect(scan_from_queue).to be_kind_of(SSHScan::Scan)

    @worker.do_work
    completed_scan = SSHScan::Scan.find_by("scan_id": scan.scan_id)
    expect(completed_scan.state).to eql("COMPLETED")
    expect(completed_scan.grade).to eql("A")
    expect(completed_scan.worker_id).to match(/^[\w]+{8}-[\w]+{4}-[\w]+{4}-[\w]+{4}-[\w]+{12}$/)
    expect(completed_scan.raw_scan).to be_kind_of(::String)
    expect(JSON.parse(completed_scan.raw_scan)).to be_kind_of(::Hash)
  end

  it "should pull items off the queue and complete them in order" do
    scan1 = SSHScan::Scan.new do |s|
      s.scan_id = SecureRandom.uuid
      s.creation_time = Time.now
      s.target = "sshscan.rubidus.com"
      s.port = 22
      s.state = "QUEUED"
      s.save
    end

    scan2 = SSHScan::Scan.new do |s|
      s.scan_id = SecureRandom.uuid
      s.creation_time = Time.now
      s.target = "sshscan.rubidus.com"
      s.port = 22
      s.state = "QUEUED"
      s.save
    end

    # Verify the scans are in the queue
    scan1_from_queue = SSHScan::Scan.find_by("scan_id": scan1.scan_id)
    expect(scan1_from_queue).to be_kind_of(SSHScan::Scan)
    scan2_from_queue = SSHScan::Scan.find_by("scan_id": scan2.scan_id)
    expect(scan1_from_queue).to be_kind_of(SSHScan::Scan)

    @worker.do_work
    completed_scan1 = SSHScan::Scan.find_by("scan_id": scan1.scan_id)
    expect(completed_scan1.state).to eql("COMPLETED")
    expect(completed_scan1.grade).to eql("A")
    expect(completed_scan1.worker_id).to match(/^[\w]+{8}-[\w]+{4}-[\w]+{4}-[\w]+{4}-[\w]+{12}$/)
    expect(completed_scan1.raw_scan).to be_kind_of(::String)
    expect(JSON.parse(completed_scan1.raw_scan)).to be_kind_of(::Hash)

    @worker.do_work
    completed_scan2 = SSHScan::Scan.find_by("scan_id": scan2.scan_id)
    expect(completed_scan2.state).to eql("COMPLETED")
    expect(completed_scan2.grade).to eql("A")
    expect(completed_scan2.worker_id).to match(/^[\w]+{8}-[\w]+{4}-[\w]+{4}-[\w]+{4}-[\w]+{12}$/)
    expect(completed_scan2.raw_scan).to be_kind_of(::String)
    expect(JSON.parse(completed_scan2.raw_scan)).to be_kind_of(::Hash)
  end

end