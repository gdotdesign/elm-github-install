require 'spec_helper'

describe ElmInstall::GraphBuilder do
  describe '.graph_from_cache' do
    let(:cache) { ElmInstall::Cache.new(directory: 'spec/fixtures') }

    it 'should generate a graph from cache' do
      graph = described_class.graph_from_cache(cache)
      names = graph.artifacts.map(&:name)
      expect(names)
        .to eq(['https://github.com/base/core',
                'https://github.com/test/test'])
    end
  end
end
