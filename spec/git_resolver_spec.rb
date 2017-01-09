require 'spec_helper'

describe ElmInstall::GitResolver do
  subject { described_class.new directory: CACHE_DIRECTORY }

  let(:uri) { 'git@github.com:test/repo' }

  context 'With cache' do
    subject { described_class.new directory: 'spec/fixtures' }

    describe '#save' do
      it 'should save cache' do
        expect(File).to receive(:binwrite)
        subject.save
      end
    end

    describe '#clear' do
      it 'should clear the cache' do
        expect do
          subject.clear
        end.to change {
          subject.instance_variable_get('@check_cache').keys.count
        }.from(2).to(0)
      end
    end
  end

  describe '.repository' do
    let(:refs) { {} }
    let(:repo) { Git.init CACHE_DIRECTORY }

    context 'with repository' do
      let(:directory) { File.join CACHE_DIRECTORY, 'github.com/test/repo' }

      before do
        FileUtils.mkdir_p directory
        Git.init directory
      end

      context 'with cache' do
        before do
          subject.instance_variable_get('@check_cache')[directory] = {}
          subject.cache[directory] = {}
        end

        it 'should return repository' do
          repo = subject.repository uri
          expect(File.dirname(repo.repo.path))
            .to eq File.join(Dir.pwd, directory)
        end
      end

      context 'without cache' do
        before do
          expect_any_instance_of(Git::Base)
            .to receive(:fetch)

          expect_any_instance_of(Git::Remote)
            .to receive(:url)
            .and_return uri.to_s

          expect(Git)
            .to receive(:ls_remote)
            .and_return(refs)

          expect(ElmInstall::Logger)
            .to receive(:arrow)
            .with "Package: #{'git@github.com:test/repo'.bold} is outdated, \
                   fetching changes...".gsub(/\s+/, ' ')
        end

        it 'should fetch refs and update cache' do
          subject.repository uri
        end
      end
    end

    context 'without repository' do
      before do
        expect(Git)
          .to receive(:clone)
          .and_return(repo)

        expect(Git)
          .to receive(:ls_remote)
          .and_return(refs)

        expect(ElmInstall::Logger)
          .to receive(:arrow)
          .with "Package: #{'git@github.com:test/repo'.bold} not found in \
                 cache, cloning...".gsub(/\s+/, ' ')
      end

      it 'should clone a new repository' do
        expect { subject.repository uri }
          .to change { subject.cache.keys.count }
          .from(0)
          .to(1)
      end
    end
  end
end
