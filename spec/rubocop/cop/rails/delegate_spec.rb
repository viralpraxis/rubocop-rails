# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Rails::Delegate, :config do
  let(:cop_config) { { 'EnforceForPrefixed' => true } }

  it 'finds trivial delegate' do
    expect_offense(<<~RUBY)
      def foo
      ^^^ Use `delegate` to define delegations.
        bar.foo
      end
    RUBY

    expect_correction(<<~RUBY)
      delegate :foo, to: :bar
    RUBY
  end

  it 'finds trivial delegate with arguments' do
    expect_offense(<<~RUBY)
      def foo(baz)
      ^^^ Use `delegate` to define delegations.
        bar.foo(baz)
      end
    RUBY

    expect_correction(<<~RUBY)
      delegate :foo, to: :bar
    RUBY
  end

  it 'finds trivial delegate to `self`' do
    expect_offense(<<~RUBY)
      def foo
      ^^^ Use `delegate` to define delegations.
        self.foo
      end
    RUBY

    expect_correction(<<~RUBY)
      delegate :foo, to: self
    RUBY
  end

  it 'does not find trivial delegate to `self` for separate `module_function` def' do
    expect_no_offenses(<<~RUBY)
      module A
        module_function

        def foo
          self.foo
        end
      end
    RUBY
  end

  it 'does not find trivial delegate to `self` for inline `module_function` def' do
    expect_no_offenses(<<~RUBY)
      module A
        module_function def foo
          self.foo
        end
      end
    RUBY
  end

  it 'finds trivial delegate with prefix' do
    expect_offense(<<~RUBY)
      def bar_foo
      ^^^ Use `delegate` to define delegations.
        bar.foo
      end
    RUBY

    expect_correction(<<~RUBY)
      delegate :foo, to: :bar, prefix: true
    RUBY
  end

  it 'finds trivial delegate to `self` when underscored method' do
    expect_offense(<<~RUBY)
      def bar_foo
      ^^^ Use `delegate` to define delegations.
        self.bar_foo
      end
    RUBY

    expect_correction(<<~RUBY)
      delegate :bar_foo, to: self
    RUBY
  end

  it 'ignores class methods' do
    expect_no_offenses(<<~RUBY)
      def self.fox
        new.fox
      end
    RUBY
  end

  it 'ignores non trivial delegate' do
    expect_no_offenses(<<~RUBY)
      def fox
        bar.foo.fox
      end
    RUBY
  end

  it 'ignores trivial delegate with mismatched arguments' do
    expect_no_offenses(<<~RUBY)
      def fox(baz)
        bar.fox(foo)
      end
    RUBY
  end

  it 'ignores trivial delegate with optional argument with a default value' do
    expect_no_offenses(<<~RUBY)
      def fox(foo = nil)
        bar.fox(foo || 5)
      end
    RUBY
  end

  it 'ignores trivial delegate with mismatched number of arguments' do
    expect_no_offenses(<<~RUBY)
      def fox(a, baz)
        bar.fox(a)
      end
    RUBY
  end

  it 'ignores trivial delegate with mismatched keyword arguments' do
    expect_no_offenses(<<~RUBY)
      def fox(foo:)
        bar.fox(foo)
      end
    RUBY
  end

  it 'ignores trivial delegate with other prefix' do
    expect_no_offenses(<<~RUBY)
      def fox_foo
        bar.foo
      end
    RUBY
  end

  it 'ignores methods with arguments' do
    expect_no_offenses(<<~RUBY)
      def fox(bar)
        bar.fox
      end
    RUBY
  end

  it 'ignores the method in the body with arguments' do
    expect_no_offenses(<<~RUBY)
      def fox
        bar(42).fox
      end
    RUBY
  end

  it 'ignores private delegations' do
    expect_no_offenses(<<~RUBY)
      private def fox # leading spaces are on purpose
        bar.fox
      end

      private

      def fox
        bar.fox
      end
    RUBY
  end

  it 'ignores protected delegations' do
    expect_no_offenses(<<~RUBY)
      protected def fox # leading spaces are on purpose
        bar.fox
      end

      protected

      def fox
        bar.fox
      end
    RUBY
  end

  it 'works with private methods declared in inner classes' do
    expect_offense(<<~RUBY)
      class A
        class B

          private

          def foo
            bar.foo
          end
        end

        def baz
        ^^^ Use `delegate` to define delegations.
          foo.baz
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class A
        class B

          private

          def foo
            bar.foo
          end
        end

        delegate :baz, to: :foo
      end
    RUBY
  end

  it 'ignores delegation with assignment' do
    expect_no_offenses(<<~RUBY)
      def new
        @bar = Foo.new
      end
    RUBY
  end

  it 'ignores code with no receiver' do
    expect_no_offenses(<<~RUBY)
      def change
        add_column :images, :size, :integer
      end
    RUBY
  end

  context 'with EnforceForPrefixed: false' do
    let(:cop_config) do
      { 'EnforceForPrefixed' => false }
    end

    it 'ignores trivial delegate with prefix' do
      expect_no_offenses(<<~RUBY)
        def bar_foo
          bar.foo
        end
      RUBY
    end
  end

  it 'ignores trivial delegate with safe navigation' do
    expect_no_offenses(<<~RUBY)
      def foo
        bar&.foo
      end
    RUBY
  end

  it 'detects delegation to `self.class`' do
    expect_offense(<<~RUBY)
      def foo
      ^^^ Use `delegate` to define delegations.
        self.class.foo
      end
    RUBY

    expect_correction(<<~RUBY)
      delegate :foo, to: :class
    RUBY
  end

  it 'detects delegation to a constant' do
    expect_offense(<<~RUBY)
      def foo
      ^^^ Use `delegate` to define delegations.
        CONST.foo
      end
    RUBY

    expect_correction(<<~RUBY)
      delegate :foo, to: :CONST
    RUBY
  end

  it 'detects delegation to a namespaced constant' do
    expect_offense(<<~RUBY)
      def foo
      ^^^ Use `delegate` to define delegations.
        SomeModule::CONST.foo
      end
    RUBY

    expect_correction(<<~RUBY)
      delegate :foo, to: :'SomeModule::CONST'
    RUBY
  end

  it 'detects delegation to a cbase namespaced constant' do
    expect_offense(<<~RUBY)
      def foo
      ^^^ Use `delegate` to define delegations.
        ::SomeModule::CONST.foo
      end
    RUBY

    expect_correction(<<~RUBY)
      delegate :foo, to: :'::SomeModule::CONST'
    RUBY
  end

  it 'detects delegation to an instance variable' do
    expect_offense(<<~RUBY)
      def foo
      ^^^ Use `delegate` to define delegations.
        @instance_variable.foo
      end
    RUBY

    expect_correction(<<~RUBY)
      delegate :foo, to: :@instance_variable
    RUBY
  end

  it 'detects delegation to a class variable' do
    expect_offense(<<~RUBY)
      def foo
      ^^^ Use `delegate` to define delegations.
        @@class_variable.foo
      end
    RUBY

    expect_correction(<<~RUBY)
      delegate :foo, to: :@@class_variable
    RUBY
  end

  it 'detects delegation to a global variable' do
    expect_offense(<<~RUBY)
      def foo
      ^^^ Use `delegate` to define delegations.
        $global_variable.foo
      end
    RUBY

    expect_correction(<<~RUBY)
      delegate :foo, to: :$global_variable
    RUBY
  end

  it 'is disabled for controllers' do
    expect_no_offenses(<<~RUBY, "#{Bundler.root}/app/controllers/foo_controller.rb")
      class FooController
        before_action :load

        def destroy
          @foo.destroy
        end

        private

        def load
          @foo = Foo.find(params[:id])
        end
      end
    RUBY
  end
end
