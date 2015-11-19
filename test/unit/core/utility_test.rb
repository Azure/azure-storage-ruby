#-------------------------------------------------------------------------
# # Copyright (c) Microsoft and contributors. All rights reserved.
#
# The MIT License(MIT)

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files(the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions :

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#--------------------------------------------------------------------------
require 'test_helper'

describe Azure::Core::Logger do
  subject { Azure::Core::Logger }
  let(:msg) { "message" }

  after {
    subject.initialize_external_logger(nil)
  }

  describe "Log without external logger" do
    before {
      subject.initialize_external_logger(nil)
    }

    it "#info" do
      out, err = capture_io { subject.info(msg) }
      assert_equal("\e[37m\e[1m" + msg + "\e[0m\e[0m\n", out)
    end

    it "#error_with_exit" do
      out, err = capture_io do
        error = assert_raises(RuntimeError) do
          subject.error_with_exit(msg)
        end
        assert_equal("\e[31m\e[1m" + msg + "\e[0m\e[0m", error.message)
      end
      assert_equal("\e[31m\e[1m" + msg + "\e[0m\e[0m\n", out)
    end

    it "#warn" do
      out, err = capture_io do
        warn = subject.warn(msg)
        assert_equal(msg, warn)
      end
      assert_equal("\e[33m" + msg + "\e[0m\n", out)
    end

    it "#error" do
      out, err = capture_io do
        error = subject.error(msg)
        assert_equal(msg, error)
      end
      assert_equal("\e[31m\e[1m" + msg + "\e[0m\e[0m\n", out)
    end

    it "#exception_message" do
      out, err = capture_io do
        exception = assert_raises(RuntimeError) do
          subject.exception_message(msg)
        end
        assert_equal("\e[31m\e[1m" + msg + "\e[0m\e[0m", exception.message)
      end
      assert_equal("\e[31m\e[1m" + msg + "\e[0m\e[0m\n", out)
    end

    it "#success" do
      out, err = capture_io { subject.success(msg) }
      assert_equal("\e[32m" + msg + "\n\e[0m", out)
    end
  end

  describe "Log with external logger" do
    let(:fake_output) { StringIO.new }

    before {
      subject.initialize_external_logger(Logger.new(fake_output))
    }

    it "#info" do
      subject.info(msg)
      assert_match(/INFO -- : #{msg}\n/, fake_output.string)
    end

    it "#error_with_exit" do
      error = assert_raises(RuntimeError) do
        subject.error_with_exit(msg)
      end
      assert_match(/ERROR -- : #{msg}\n/, fake_output.string)
      assert_equal("\e[31m\e[1m" + msg + "\e[0m\e[0m", error.message)
    end

    it "#warn" do
      warn = subject.warn(msg)
      assert_match(/WARN -- : #{msg}\n/, fake_output.string)
      assert_equal(msg, warn)
    end

    it "#error" do
      error = subject.error(msg)
      assert_match(/ERROR -- : #{msg}\n/, fake_output.string)
      assert_equal(msg, error)
    end

    it "#exception_message" do
      exception = assert_raises(RuntimeError) do
        subject.exception_message(msg)
      end
      assert_match(/WARN -- : #{msg}\n/, fake_output.string)
      assert_equal("\e[31m\e[1m" + msg + "\e[0m\e[0m", exception.message)
    end

    it "#success" do
      subject.success(msg)
      assert_match(/INFO -- : #{msg}\n/, fake_output.string)
    end
  end
end