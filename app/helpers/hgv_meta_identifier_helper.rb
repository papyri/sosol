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

            data_item[:certaintyPicker] = data_item.select{|k,v| k.to_s.include?('Certainty') && !v.empty?}.collect{|v| v[0].to_s.include?('Certainty') ? v[0].to_s[/(Day|Month|Year)/].downcase : nil}.compact.sort.join('_')
            data_item[:certaintyPicker] = !data_item[:certaintyPicker].empty? ? data_item[:certaintyPicker] : data_item[:certainty]

          end
        end
        data[data.length] = data_item
      }

      data
    end
  end
  
  module HgvFuzzy
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