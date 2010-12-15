module HgvMetaIdentifierHelper

  module HgvDate
    def HgvDate.monthOptions
      [['', ''], ['beginning', 'beginning'], ['middle', 'middle'], ['end', 'end']]
    end
    def HgvDate.yearOptions
      [['', ''], ['beginning', 'beginning'], ['first half', 'first_half'], ['first half to middle', 'first_half_to_middle'], ['middle', 'middle'], ['middle to second half', 'middle_to_second_half'], ['second half', 'second_half'], ['end', 'end']]
    end
    def HgvDate.offsetOptions
      [['', ''], ['before', 'before'], ['after', 'after']]
    end
    def HgvDate.certaintyOptions
      [['', ''], ['Probably...', 'high'], ['(?)', 'low'], ['Day uncertain', 'day'], ['Month and year uncertain', 'month_year'], ['Year uncertain', 'year']]
    end
    def HgvDate.childBase date_index, date_type
      'hgv_meta_identifier[textDate][' + date_index.to_s + '][children][' + date_type + 'Date][children]'
    end
    def HgvDate.attributeBase date_index, date_type
      'hgv_meta_identifier[textDate][' + date_index.to_s + '][children][' + date_type + 'Date][attributes]'
    end  
    def HgvDate.dateInformation date_item

      data = {:century => {:value => '', :extent => '', :certainty => ''}, :year => {:value => '', :extent => '', :certainty => ''}, :month => {:value => '', :extent => '', :certainty => ''}, :day => {:value => '', :extent => '', :certainty => ''}, :offset => '', :certainty => '', :certaintyPicker => ''}
      data[:certainty] = date_item && date_item[:attributes] && date_item[:attributes][:certainty] ? date_item[:attributes][:certainty] : ''

      if date_item && date_item[:children]
        data.each_key { |key|
          if date_item[:children][key]
            data[key][:value] = date_item[:children][key][:value] ? date_item[:children][key][:value] : ''
            data[key][:extent] = date_item[:children][key][:attributes][:extent] ? date_item[:children][key][:attributes][:extent] : ''
            data[key][:certainty] = date_item[:children][key][:attributes][:certainty] ? date_item[:children][key][:attributes][:certainty] : ''
          end
        }
        data[:offset] = date_item[:children][:offset] && date_item[:children][:offset][:value] ? date_item[:children][:offset][:value] : ''

      end

      data[:certaintyPicker] = data[:certainty] != '' ? data[:certainty] : {:day => data[:day][:certainty], :month => data[:month][:certainty], :year => data[:year][:certainty]}.reject{|k, v| v.empty? }.keys.join('_')

      data
    end
  end

  module HgvMentionedDate
    def HgvMentionedDate.certaintyOptions
      [['', ''], ['(?)', '0.7'], ['Day uncertain', 'day'], ['Day and month uncertain', 'day_month'], ['Month uncertain', 'month'], ['Month and year uncertain', 'month_year'], ['Year uncertain', 'year']]
    end
    def HgvMentionedDate.dateIdOptions
      [['', ''], ['X', '#dateAlternativeX'], ['Y', '#dateAlternativeY'], ['Z', '#dateAlternativeZ']]
    end
    def HgvMentionedDate.dateInformation mentioned_date
      data = []

      mentioned_date.each { |item|
        data_item = {:date => '', :ref => '', :certainty => '', :certaintyPicker => '', :dateId => '', :note => '', :when => '', :whenDayCertainty => '',:whenMonthCertainty => '',:whenYearCertainty => '', :from => '', :fromDayCertainty => '', :fromMonthCertainty => '', :fromYearCertainty => '', :to => '', :toDayCertainty => '',:toMonthCertainty => '',:toYearCertainty => ''}
        if item[:children]
          item[:children].each_pair{|key, value|
            data_item[key] = value && value[:value] ? value[:value] : ''
          }
          if item[:children][:date] && item[:children][:date][:attributes]
              item[:children][:date][:attributes].each_pair {|key, value|
                data_item[key] = value ? value : ''
              }
          end
          if item[:children][:date] && item[:children][:date][:children] && item[:children][:date][:children][:certainty]
            item[:children][:date][:children][:certainty].each {|certainty|
              if certainty[:attributes]
                if certainty[:attributes][:relation]
                  data_item[:dateId] = certainty[:attributes][:relation]
                elsif certainty[:attributes][:target] && certainty[:attributes][:degree]
                  key = certainty[:attributes][:target][/@(when|from|to),/, 1] + {1 => :Year, 6 => :Month, 9 => :Day}[certainty[:attributes][:target][/,.*(\d).*,/, 1].to_i].to_s + 'Certainty'
                  data_item[key.to_sym] = certainty[:attributes][:degree]
                elsif certainty[:attributes][:degree]
                  data_item[:certainty] = certainty[:attributes][:degree]
                end
              end
            }

            data_item[:certaintyPicker] = data_item.select{|k,v| k.to_s.include?('Certainty') && k.to_s[/(Day|Month|Year)/] && !v.empty?}.collect{|v| v[0].to_s.include?('Certainty') ? v[0].to_s[/(Day|Month|Year)/].downcase : nil}.compact.sort.join('_')
            data_item[:certaintyPicker] = !data_item[:certaintyPicker].empty? ? data_item[:certaintyPicker] : data_item[:certainty]

          end
        end
        data[data.length] = data_item
      }

      data
    end
  end
  
  module HgvFormat
    def HgvFormat.keyStringToSym hashIn
      hashOut = {}
      hashIn.each_pair {|k,v|
        hashOut[k.to_sym] = (v.is_a?(Hash) ? keyStringToSym(v) : v)
      }
      hashOut
    end
    
    
    def HgvFormat.formatDate date1, date2 = nil
      #{:century => {:value => '', :extent => '', :certainty => ''}, :year => {:value => '', :extent => '', :certainty => ''}, :month => {:value => '', :extent => '', :certainty => ''}, :day => {:value => '', :extent => '', :certainty => ''}, :offset => '', :certainty => '', :certaintyPicker => ''}
      
      date1 = keyStringToSym date1
      
      if date2
        date2 = keyStringToSym date2

        [:century, :year, :month].each{|item|
          if date1[item][:value] == date2[item][:value] 
            date1[item][:value] =  nil
            if date1[item][:extent] == date2[item][:extent]
              date1[item][:extent] =  nil
            end
          end
        }

      end

      certainty = formatCertaintyPart date1, date2

      date1 = formatDatePart(
        date1[:century][:value],
        date1[:year][:value],
        date1[:month][:value],
        date1[:day][:value],
        date1[:century][:extent],
        date1[:year][:extent],
        date1[:month][:extent],
        date1[:offset],
        date1[:certainty]
      )

      if date2
        date2 = formatDatePart(
          date2[:century][:value],
          date2[:year][:value],
          date2[:month][:value],
          date2[:day][:value],
          date2[:century][:extent],
          date2[:year][:extent],
          date2[:month][:extent],
          date2[:offset],
          date2[:certainty]
        )
      end

      return (date2 && date2.include?(' v.Chr.') ? date1.sub(/ v\.Chr\./, '') : date1) + 
             (date2 && !date2.empty? ? ' - ' + date2 : '') + 
             (!certainty.empty? ? ' ' + certainty : '')
    end

    def HgvFormat.formatDatePart c = nil, y = nil, m = nil, d = nil, cq = nil, yq = nil, mq = nil, offset = nil, certainty = nil

      offset = formatOffset offset
      m = formatMonth m
      d = formatDay d
      y = formatYear y
      c = formatCentury c
      mq = formatMonthQualifier mq
      yq = formatYearQualifier yq
      cq = formatCenturyQualifier cq

      return  (certainty && [:high, 'high'].include?(certainty) ? 'ca. ' : '') +
              ((!offset.empty? ? offset + ' ' : '') +
              (!d.empty? ? (d + ' ') : '') +
              (!mq.empty? ? mq + ' ' : '') +
              (!m.empty? ? m + ' ' : '') +
              (!yq.empty? ? yq + ' ' : '') +
              (!y.empty? ? y.to_s + ' ' : '') +
              (!cq.empty? ? cq + ' ' : '') +
              (!c.empty? ? c : '')).strip +
              (certainty && certainty.to_s == 'low' ? ' (?)' : '')
    end

    def HgvFormat.formatCertaintyPart date1, date2
      uncertainties = []
      [date1, date2].each{|date|
        if date.class == Hash
          date.each_pair{|k, v|
            if v.class == Hash
              v.each_pair{|l, w|
                if l == :certainty && ['low', :low].include?(w)
                  uncertainties[uncertainties.length] = k
                end
              }
            end
          }
        end
      }

      uncertainties = uncertainties.uniq.collect{|item|
        {:century => 'Jahrhundert', :year => 'Jahr', :month => 'Monat', :day => 'Tag'}[item]
      }.join(', ').sub(/, [^,]+$/) {|match| match.sub(/, /, ' und ')}
      
      return !uncertainties.empty? ? '(' + uncertainties + ' unsicher)' : ''
    end

    def HgvFormat.formatOffset offset
      offset = {:before => 'vor', :after => 'nach'}[offset.class == Symbol ? offset : (offset.class == String && !offset.empty? ? offset.to_sym : nil)]
      return  offset ? offset : ''
    end
    def HgvFormat.formatDay day
      return  (day && day.to_i > 0) ? (day.to_i.to_s + '.') : ''
    end
    def HgvFormat.formatMonth month
      months = ['', 'Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.', 'Sept.', 'Okt.', 'Nov.', 'Dez.']
      return month && month.to_i > 0 && month.to_i < 13 ? months[month.to_i] : ''
    end
    def HgvFormat.formatYear year
      return year && year.to_i != 0 ? year.to_i.abs.to_s + (year.to_i < 0 ? ' v.Chr.' :'') : ''
    end
    def HgvFormat.formatCentury century
      return century && century.to_i != 0 ? century.to_i.abs.roman.to_s + (century.to_i < 0 ? ' v.Chr.' :'') : ''
    end
    def HgvFormat.formatMonthQualifier q
      q = q.class == Symbol ? q : q.class == String && !q.empty? ? q.to_sym : nil
      map = {:beginning => 'Anfang', :middle => 'Mitte', :end => 'Ende'}
      return map.has_key?(q) ? map[q] : '' 
    end
    def HgvFormat.formatYearQualifier q
      q = q.class == Symbol ? q : q.class == String && !q.empty? ? q.to_sym : nil
      map = {:beginning => 'Anfang', :first_half => '1. Hälfte', :first_half_to_middle => 'Mitte', :middle => 'Mitte', :middle_to_second_half => 'Mitte', :second_half => '2. Hälfte', :end => 'Ende'}
      return map.has_key?(q) ? map[q] : '' 
    end
    def HgvFormat.formatCenturyQualifier q
      q = q.class == Symbol ? q : q.class == String && !q.empty? ? q.to_sym : nil
      map = {:beginning => 'Anfang', :first_half => '1. Hälfte', :first_half_to_middle => 'Mitte', :middle => 'Mitte', :middle_to_second_half => 'Mitte', :second_half => '2. Hälfte', :end => 'Ende'}
      return map.has_key?(q) ? map[q] : '' 
    end
  end

  module HgvFuzzy
    def HgvFuzzy.getChronSimple c, y, m, d, cq, yq, mq, chron = :chron
      if chron == :chron && c.to_i != 0
        ''
      else
        intelligent_date = getChron c, y, m, d, cq, yq, mq, chron
  
        # throw away month and day if they were not explicitely set by the user      
        if m.to_i == 0
          intelligent_date[0..-7]
        elsif d.to_i == 0
          intelligent_date[0..-4]
        else
          intelligent_date
        end
      end
    end

    def HgvFuzzy.getChron c, y, m, d, cq, yq, mq, chron = :chron
      c = c.to_i != 0 ? c.to_i : nil
      y = y.to_i != 0 ? y.to_i : nil
      m = m.to_i != 0 ? m.to_i : nil
      d = d.to_i != 0 ? d.to_i : nil

      epoch = year = month = day = nil;      

      year_modifier = {
        :chron => {
          '' => 13,
          'beginning' => 13,
          'first_half' => 13,
          'first_half_to_middle' => 38,
          'middle' => 38,
          'middle_to_second_half' => 63,
          'second_half' => 63,
          'end' => 87
        },
        :chronMin => {
          '' => 0,
          'beginning' => 0,
          'first_half' => 0,
          'first_half_to_middle' => 25,
          'middle' => 25,
          'middle_to_second_half' => 50,
          'second_half' => 50,
          'end' => 75
        },
        :chronMax => {
          '' => 0,
          'beginning' => -75,
          'first_half' => -50,
          'first_half_to_middle' => -50,
          'middle' => -25,
          'middle_to_second_half' => -25,
          'second_half' => 0,
          'end' => 0
        }
      }[chron][cq]

      month_modifier = {
        :chron => {
          '' => '02',
          'beginning' => '02',
          'first_half' => '03',
          'first_half_to_middle' => '05',
          'middle' => '06',
          'middle_to_second_half' => '08',
          'second_half' => '09',
          'end' => '11'
        },
        :chronMin => {
          '' => '01',
          'beginning' => '01',
          'first_half' => '01',
          'first_half_to_middle' => '04',
          'middle' => '04',
          'middle_to_second_half' => '07',
          'second_half' => '07',
          'end' => '10'
        },
        :chronMax => {
          '' => '12',
          'beginning' => '03',
          'first_half' => '06',
          'first_half_to_middle' => '06',
          'middle' => '09',
          'middle_to_second_half' => '09',
          'second_half' => '12',
          'end' => '12'
        }
      }[chron][yq]
      
      m = m ? m : month_modifier.to_i
      day_max = m ? (m != 2 ? (m < 8 ? ((m % 2) == 0 ? 30 : 31) : ((m % 2) == 0 ? 31 : 30) ) : (y && ((y % 4) == 0) && (((y % 100) != 0) || ((y % 400) == 0)) ? 29 : 28)) : 31
      day_modifier = {
        :chron => {
          '' => '04',
          'beginning' => '04',
          'middle' => '15',
          'end' => '26'
        },
        :chronMin => {
          '' => '01',
          'beginning' => '01',
          'middle' => '11',
          'end' => '21'
        },
        :chronMax => {
          '' => day_max.to_s,
          'beginning' => '10',
          'middle' => '20',
          'end' => day_max.to_s
        }
      }[chron][mq]

      if y
        epoch = y < 0 ? '-' : ''
        year = y.abs.to_s.rjust(4, '0')
      elsif c
        epoch = c < 0 ? '-' : ''
        if chron == :chronMax
          year = c > 0 ? (c * 100 + year_modifier).to_s.rjust(4, '0') : ((c + 1) * 100 + year_modifier - 1).abs.to_s.rjust(4, '0')
        else
          year = c < 0 ? (c * 100 + year_modifier).abs.to_s.rjust(4, '0') : ((c - 1) * 100 + year_modifier + 1).to_s.rjust(4, '0')
        end
      else
        return '' # if we have no year there is no go
      end
      
      if m
        month = m.to_s.rjust(2, '0')
      else
        month = month_modifier
      end
      
      if d
        day = d.to_s.rjust(2, '0')
      else
        day = day_modifier
      end

      epoch + year + '-' + month + '-' + day
    end
    
    def HgvFuzzy.getChronMin c, y, m, d, cq, yq, mq
      return HgvFuzzy.getChron c, y, m, d, cq, yq, mq, :chronMin
    end

    def HgvFuzzy.getChronMax c, y, m, d, cq, yq, mq
      return HgvFuzzy.getChron c, y, m, d, cq, yq, mq, :chronMax
    end
  end

end

class Integer # ruby.brian-amberg.de
  # Used for Integer to Roman conversion. (#roman)
  @@roman_values_assoc = %w(I IV V IX X XL L XC C CD D CM M).zip([1, 4, 5, 9, 10, 40, 50, 90, 100, 400, 500, 900, 1000]).reverse

  # Used for Roman to Integer conversion. (Integer#roman)
  @@roman_values = @@roman_values_assoc.inject({}) { |h, (r,a)| h[r] = a; h }

  # Spits out the number as a roman number
  def roman
    return "-#{(-self).roman}" if self < 0
    return "" if self == 0
    @@roman_values_assoc.each do | (i, v) | return(i+(self-v).roman) if v <= self end
  end

  # Returns a roman number string
  def Integer.roman(roman)
    last = roman[-1,1]
    roman.reverse.split('').inject(0) { | result, c |
      if @@roman_values[c] < @@roman_values[last]
        result -= @@roman_values[c]
      else
        last = c
        result += @@roman_values[c]
      end
    }
  end
end # ruby.brian-amberg.de