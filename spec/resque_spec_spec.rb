require 'spec_helper'

describe "ResqueSpec" do
  before do
    ResqueSpec.reset!
  end

  let(:first_name) { 'Les' }
  let(:last_name) { 'Hill' }

  describe "#queue_for" do
    it "raises if there is no queue defined for a class" do
      expect do
        ResqueSpec.queue_for(Address)
      end.should raise_exception(::Resque::NoQueueError)
    end

    it "recognizes a queue defined as a class instance variable" do
      expect do
        ResqueSpec.queue_for(Person)
      end.should_not raise_exception(::Resque::NoQueueError)
    end

    it "recognizes a queue defined as a class method" do
      expect do
        ResqueSpec.queue_for(Account)
      end.should_not raise_exception(::Resque::NoQueueError)
    end

    it "has an empty array if nothing queued for a class" do
      ResqueSpec.queue_for(Person).should == []
    end

    it "allows additions" do
      ResqueSpec.queue_for(Person) << 'queued'
      ResqueSpec.queue_for(Person).should_not be_empty
    end
  end

  describe "#reset!" do
    it "clears the queues" do
      ResqueSpec.queue_for(Person) << 'queued'
      ResqueSpec.reset!
      ResqueSpec.queues.should be_empty
    end
  end

  describe "in_queue?" do

    it "returns true if the arguments were queued" do
      Resque.enqueue(Person, first_name, last_name)
      ResqueSpec.in_queue?(Person, first_name, last_name).should be
    end

    it "returns false if the arguments were not queued" do
      ResqueSpec.in_queue?(Person, first_name, last_name).should_not be
    end

  end

  describe "run!" do
    it "runs queued jobs" do
      $_job_has_run = false
      class InlineJob
        @queue = :spec
        def self.perform
          $job_has_run = true
        end
      end

      Resque.enqueue( InlineJob )
      ResqueSpec.run!

      $job_has_run.should be
    end
  end

  describe "Resque" do
    describe "#enqueue" do

      before do
        Resque.enqueue(Person, first_name, last_name)
      end

      it "adds to the queue hash" do
        ResqueSpec.queue_for(Person).should_not be_empty
      end

      it "sets the klass on the queue" do
        ResqueSpec.queue_for(Person).first.should include(:klass => Person)
      end

      it "sets the arguments on the queue" do
        ResqueSpec.queue_for(Person).first.should include(:args => [first_name, last_name])
      end

    end
  end

  context "Matchers" do
    before do
      Resque.enqueue(Person, first_name, last_name)
    end

    describe "#have_queued" do
      it "returns true if the arguments are found in the queue" do
        Person.should have_queued(first_name, last_name)
      end

      it "returns false if the arguments are not found in the queue" do
        Person.should_not have_queued(last_name, first_name)
      end
    end
  end
end
