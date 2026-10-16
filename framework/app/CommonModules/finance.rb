# Derived from Exonio library at https://github.com/noverde/exonio

require 'bigdecimal'
require 'bigdecimal/newton'
require "bigdecimal/util"

module Finance
	module Helpers
		class IrrHelper
			values = {
				eps: '1.0e-16',
				one: '1.0',
				two: '2.0',
				ten: '10.0',
				zero: '0.0'
			}

			values.each do |key, value|
				define_method key do
					BigDecimal.new(value)
				end
			end

			def initialize(transactions, guess=nil)
				@transactions = transactions
				if guess.to_s != ""
					define_singleton_method "eps" do
						BigDecimal.new(guess.to_s)
					end
				end
			end

			def values(x)
				value = Finance.npv(x[0].to_f, @transactions)
				[ value.to_d ]
			end
		end
	end

	module Financial
		# Calculates the future value of an annuity investment based on
		# constant-amount periodic payments and a constant interest rate.
		#
		# @param rate [Float] The interest rate as decimal (not per cent) per period
		# @param nper [Integer] The number of compounding periods
		# @param pmt [Float] The number of payments to be made
		# @param pv [Float] The present value
		# @param end_or_begining [Integer] Whether payments are due at the end (0) or
		#   beggining (1) of each period
		#
		# @return [Float]
		#
		# @example
		#   Finance.fv(0.05 / 12, 12 * 10, -100, -100) # ==> 15692.928894335748
		#
		def fv(rate, nper, pmt, pv, end_or_beginning = 0)
			temp = (1 + rate) ** nper
			fact = (1 + rate* end_or_beginning) * (temp - 1) / rate

			-(pv * temp + pmt * fact)
		end

		# Calculates the payment on interest for an investment based on
		# constant-amount periodic payments and a constant interest rate.
		#
		# @param rate [Float] The interest rate as decimal (not per cent) per period
		# @param per [Integer] The amortization period, in terms of number of periods
		# @param nper [Integer] The number of payments to be made
		# @param pv [Float] The present value
		# @param fv [Float] The future value remaining after the final payment has been made
		# @param end_or_begining [Integer] Whether payments are due at the end (0) or
		#   beggining (1) of each period
		#
		# @return [Float]
		#
		# @example
		#   Finance.ipmt(0.075 / 12, 8, 12 * 2, 5000) # ==> -22.612926783996798
		#
		def ipmt(rate, per, nper, pv, fv = 0, end_or_beginning = 0)
			pmt = self.pmt(rate, nper, pv, fv, end_or_beginning)
			fv = self.fv(rate, (per - 1), pmt, pv, end_or_beginning) * rate
			temp = end_or_beginning == 1 ? fv / (1 + rate) : fv

			(per == 1 && end_or_beginning == 1) ? 0.0 : temp
		end

		# Calculates the number of payment periods for an investment based on
		# constant-amount periodic payments and a constant interest rate.
		#
		# @param rate [Float] The interest rate as decimal (not per cent) per period
		# @param pmt [Float] The payment amount made each period
		# @param pv [Float] The present value of the payments
		# @param fv [Float] The future value remaining after the final payment has been made
		# @param end_or_begining [Integer] Whether payments are due at the end (0) or
		#   beggining (1) of each period
		#
		# @return [Float]
		# 
		# @example
		#   Finance.nper(0.07 / 12, -150, 8000) # ==> 64.07334877066185
		#
		def nper(rate, pmt, pv, fv = 0, end_or_beginning = 0)
			z = pmt * (1 + rate * end_or_beginning) / rate
			temp = Math.log((-fv + z) / (pv + z))

			temp / Math.log(1 + rate)
		end

		# Calculates the periodic payment for an annuity investment based on
		# constant-amount periodic payments and a constant interest rate.
		#
		# @param rate [Float] The interest rate as decimal (not per cent) per period
		# @param nper [Integer] The number of payments to be made (number of periods)
		# @param pv [Float] The present value of the annuity
		# @param fv [Float] The future value remaining after the final payment has been made
		# @param end_or_begining [Integer] Whether payments are due at the end (0) or
		#   beggining (1) of each period
		#
		# @return [Float]
		#
		# @example
		#   Finance.pmt(0.075/12, 12*15, 200_000) # ==> -1854.0247200054619
		#
		def pmt(rate, nper, pv, fv = 0, end_or_beginning = 0)
			temp = (1 + rate) ** nper
			fact = (1 + rate * end_or_beginning) * (temp - 1) / rate

			-(fv + pv * temp) / fact
		end

		# Calculates the present value of an annuity investment based on
		# constant-amount periodic payments and a constant interest rate.
		#
		# @param rate [Float] The interest rate as decimal (not per cent) per period
		# @param nper [Integer] The number of payments to be made (number of periods)
		# @param pmt [Float] The amount per period to be paid
		# @param fv [Float] The future value remaining after the final payment has been made
		# @param end_or_begining [Integer] Whether payments are due at the end (0) or
		#   beggining (1) of each period
		#
		# @return [Float]
		#
		# @example
		#   Finance.pv(0.05/12, 12*10, -100, 20_000) # ==> -2715.0857731569663
		#
		def pv(rate, nper, pmt, fv = 0, end_or_beginning = 0)
			temp = (1 + rate) ** nper
			fact = (1 + rate * end_or_beginning) * (temp - 1) / rate

			-(fv + pmt * fact) / temp
		end

		# Calculates the interest rate of an annuity investment based on
		# constant-amount periodic payments and the assumption of a constant interest rate.
		#
		# @param nper [Integer] The number of payments to be made (number of periods)
		# @param pmt [Float] The amount per period to be paid
		# @param pv [Float] The present value
		# @param fv [Float] The future value remaining after the final payment has been made
		# @param end_or_begining [Integer] Whether payments are due at the end (0) or
		#   beggining (1) of each period
		# @param rate_guess [Float] An estimate for what the interest rate will be
		#
		# @return [Float]
		#
		# @example
		#   Finance.rate(12, 363.78, -3056.00) # ==> 0.05963422268883278
		#
		def rate(nper, pmt, pv, fv = 0, end_or_beginning = 0, rate_guess = 0.10)
			guess = rate_guess
			tolerancy = 1e-6
			close = false

			begin
				temp = newton_iter(guess, nper, pmt, pv, fv, end_or_beginning)
				next_guess = (guess - temp).round(20)
				diff = (next_guess - guess).abs
				close = diff < tolerancy
				guess = next_guess
			end while !close

			next_guess
		end

		# Calculates the net present value of an investment based on a
		# series of periodic cash flows and a discount rate.
		#
		# @param discount [Float] The discount rate of the investment over one period
		# @param cashflows [Array] The first future cash flow + additional future cash flows
		#
		# @return [Float]
		#
		# @example
		#   Finance.npv(0.281, [-100, 39, 59, 55, 20]) # ==> -0.00661872883563408
		#
		def npv(discount, cashflows)
			total = 0

			cashflows.each_with_index do |cashflow, index|
				total += (cashflow.to_f / (1 + discount.to_f) ** (index + 1))
			end

			total
		end

		# Calculates the internal rate of return on an investment based on a
		# series of periodic cash flows.
		#
		# @param cashflows [Array] An array containing the income or payments
		# associated with the investment
		#
		# @return [Float]
		#
		# @example
		#   Finance.irr([-100, 39, 59, 55, 20]) # ==> 0.28094842116...
		#
		def irr(values, guess=nil)
			func = Helpers::IrrHelper.new(values, guess)
			guess = [ func.eps ]
			nlsolve( func, guess)
			guess[0]
		end

		private

		# This method was borrowed from the NumPy rate formula
		# which was generated by Sage
		#
		def newton_iter(r, n, p, x, y, w)
			t1 = (r+1)**n
			t2 = (r+1)**(n-1)
			((y + t1*x + p*(t1 - 1)*(r*w + 1)/r) / (n*t2*x - p*(t1 - 1)*(r*w + 1)/(r**2) + n*p*t2*(r*w + 1)/r + p*(t1 - 1)*w/r))
		end
	end

	module Statistical
		# Sum of all numbers
		#
		# @param numbers_ary [array] and array of numbers to sum all elements
		#
		# @return [float]
		#
		# @example
		#   Finance.sum([1,2,3,4,5]) # => 15
		def sum(numbers_ary)
			numbers_ary.inject(0, :+)
		end

		# Simple mean formula: sum elements and / by length
		#
		# @param numbers_ary [array] an array of numbers to calculate the mean
		#
		# @return [float]
		#
		# @example
		#   Finance.mean([1,2,3,4,5]) # => 3.0
		def mean(numbers_ary)
			numbers_ary.inject(0) { |sum, i| sum + i }.to_f / numbers_ary.size
		end

		# Median formula
		# @param numbers_ary [array] an array of numbers
		#
		# @return [float]
		#
		# @example
		#   Finance.median([1,2,3,4,5]) # => 3.0
		def median(numbers_ary)
			numbers_ary.sort!
			len = numbers_ary.length
			(numbers_ary[(len - 1) / 2] + numbers_ary[len / 2]) / 2.0
		end
	end

	extend Newton
	extend Financial
	extend Statistical
end