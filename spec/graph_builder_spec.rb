require 'spec_helper'

describe ElmInstall::GraphBuilder do
  let(:cache) { ElmInstall::Cache.new(directory: 'spec/fixtures') }

  subject { described_class.new cache, verbose: true }

  describe '.graph_from_cache' do
    it 'should generate a graph from cache' do
      graph = described_class.graph_from_cache(cache)
      names = graph.artifacts.map(&:name)
      expect(names)
        .to eq(['https://github.com/base/core',
                'https://github.com/test/test'])
    end
  end

  describe '.add_version' do
    it 'should rescue from errors' do
      expect(subject).to receive(:puts)

      subject.send(:add_version, 'test', 'asd', {})
    end
  end

  describe '.add_dependency' do
    let(:artifact) { double :artifact }

    it 'should rescue from errors' do
      expect(subject).to receive(:puts)
      expect(artifact).to receive(:depends).and_raise 'test'

      subject.send(:add_dependency, artifact, 'asd', {})
    end
  end
end
