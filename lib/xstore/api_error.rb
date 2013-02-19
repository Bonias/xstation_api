module XStore

  class ApiError < StandardError
    attr :code

    def initialize(code, desc=nil)
      @code = code
      msg = "#{code}: #{self.class.error_message(code)}"
      msg << "(#{desc})" if desc
      super(msg)
    end

    def self.error_message(code)
      message = nil
      if code.to_s[0, 2] == "BE"
        errors = {
            'BE001' => "Invalid price",
            'BE002' => "Invalid StopLoss or TakeProfit",
            'BE003' => "Invalid Volume",
            'BE004' => "Login disabled",
            'BE005' => "Login not found",
            'BE006' => "Market for instrument is closed",
            'BE007' => "Mismatched parameters",
            'BE008' => "Modification is denied",
            'BE009' => "Not enough money on account to perform trade",
            'BE010' => "Off quotes",
            'BE011' => "Opposite positions prohibited",
            'BE012' => "Short positions prohibited",
            'BE013' => "Price has changed",
            'BE014' => "Request too frequent",
            'BE015' => "Requote",
            'BE016' => "Too many trade requests",
            'BE017' => "Too many trade requests",
            'BE018' => "Trading on instrument disabled",
            'BE019' => "Trading timeout",
            #'BE020-BE033' => "Other error",
            #'BE099' => "Other error",
            'BE094' => "Symbol do not exist for given account",
            'BE095' => "Account cannot trade on given symbol",
            'BE096' => "Pending order cannot be closed. Pending order must be deleted",
            'BE097' => "Cannot close already closed order",
            'BE098' => "No such transaction",
            'BE101' => "Unknown instrument symbol",
            'BE102' => "Unknown transaction type",
            'BE103' => "User is not logged",
            'BE104' => "Method not exist",
            'BE105' => "Too frequent login tries"
        }.merge(
            ((20..33).to_a + [99]).inject({}) { |h, i| h["BE#{i.to_s.rjust(3, "0")}"] = "Other error"; h }
        )

        message = errors[code]
      elsif code.to_s[0, 2] == "BE" || code.to_s[0, 2] == "SE"
        message = "Internal error, in case of such error, please contact support"
      end

      message || "Unknown error code: #{code}"
    end
  end
end