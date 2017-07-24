describe ElmInstall::GitSource do
  subject { described_class.new uri, branch }

  let(:uri) do
    ElmInstall::Uri::Ssh(GitCloneUrl.parse('git@github.com:test/repo'))
  end

  let(:branch) do
    ElmInstall::Branch::Nothing()
  end

  before do
    subject.options = { cache_directory: CACHE_DIRECTORY }
    allow(repository).to receive(:cloned?).and_return true
  end

  let(:repository) do
    double
  end

  describe '#repository' do
    it 'returns the repository' do
      subject.repository
    end

    context 'Github' do
      let(:uri) do
        ElmInstall::Uri::Github('test/repo')
      end

      it 'returns the repository' do
        subject.repository
      end
    end
  end

  context 'With repository' do
    before do
      allow(subject)
        .to receive(:repository)
        .and_return(repository)
    end

    context 'Github' do
      let(:uri) do
        ElmInstall::Uri::Github('test/repo')
      end

      it 'returns the versions' do
        expect(repository)
          .to receive(:fetch)

        expect(repository)
          .to receive(:versions)
          .and_return([Semverse::Version.new('1.0.0')])

        subject.versions([])
      end
    end

    context 'Ssh' do
      describe '#fetch' do
        it 'checks out the given version' do
          expect(repository)
            .to receive(:checkout)
            .with('1.0.0')
            .and_return(Dir.new('.'))

          subject.fetch(Semverse::Version.new('1.0.0'))
        end

        context 'With branch' do
          let(:branch) do
            ElmInstall::Branch::Just('test')
          end

          it 'checkout out the reference' do
            expect(repository)
              .to receive(:checkout)
              .with('test')
              .and_return(Dir.new('.'))

            subject.fetch(Semverse::Version.new('1.0.0'))
          end

          describe '#versions' do
            it 'returns the versions' do
              expect(repository)
                .to receive(:fetch)

              expect(subject)
                .to receive(:identifier)
                .and_return(double(version: Semverse::Version.new('1.0.0')))

              expect(repository)
                .to receive(:checkout)
                .and_return(Dir.new('.'))

              subject.versions([])
            end
          end
        end
      end

      describe '#versions' do
        it 'returns the versions' do
          expect(repository)
            .to receive(:fetch)

          expect(repository)
            .to receive(:versions)
            .and_return([Semverse::Version.new('1.0.0')])

          subject.versions([])
        end
      end
    end
  end
end
