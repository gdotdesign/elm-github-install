describe ElmInstall::Utils do
  subject { described_class }

  let(:package_variations) do
    [
      'https://github.com/test/repo',
      'git://github.com/test/repo',
      'git@github.com:test/repo'
    ]
  end

  describe '.transform_constraint' do
    it 'should convert basic constraint' do
      expect(subject.transform_constraint('0.1.0 <= v < 1.0.0'))
        .to eq(
          [Solve::Constraint.new('< 1.0.0'),
           Solve::Constraint.new('>= 0.1.0')]
        )
    end

    it 'should convert advanced constraint' do
      expect(subject.transform_constraint('0.1.0 < v <= 1.0.0'))
        .to eq(
          [Solve::Constraint.new('<= 1.0.0'),
           Solve::Constraint.new('> 0.1.0')]
        )
    end
  end
end
