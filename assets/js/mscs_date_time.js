//
// Copyright @E-MetroTel 2015
//

//                   J   F   M   A   M   J   J   A   S   O   N   D
const month_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
const month_names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul",
                     "Aug", "Sep", "Oct", "Nov", "Dec"];

(function() {
  console.log('loading mscs_date_time')
  var DateTime = {
    date_time_default: function() {
      return {year: 5, month: 1, day: 1, hour: 8, minute: 0, second: 0}
    },
    time_format: "24-hour",
    date_format: "day-first",
    update: function(dt) {
      reset_date_and_time(this)
    },
    display: function() {
      this.display_date()
      this.display_time()
    },
    display_date: function() {
      if (this.date_time.year == undefined)
        this.date_time = this.date_time_default()
      $('.dt.date').html(format_date(this, this.date_time.year, this.date_time.month, this.date_time.day))
    },
    display_time: function() {
      $('.dt.time').html(format_time(this, this.date_time.hour, this.date_time.minute, this.date_time.second))
    },
    start_timer: function() {
      reset_date_and_time(this)
      setTimeout(date_and_time_timer, 1000, this)
    },
    set_time_format: function(format) {
      this.time_format = format
      this.display()
    },
    set_date_format: function(format) {
      this.date_format = format
      this.display()
    }
  }

  DateTime.date_time = DateTime.date_time_default();
  window.Mscs.DateTime = DateTime;
})();

function reset_date_and_time(dt) {
  var d = new Date()
  var hour = d.getHours()

  dt.date_time = {year: d.getYear() - 100, month: d.getMonth() + 1, day: d.getDate(),
     hour: hour, minute: d.getMinutes(), second: d.getSeconds()}
}

function date_and_time_timer(dt) {
  reset_date_and_time(dt)
  dt.display()
  setTimeout(date_and_time_timer, 1000, dt)
}

function pad(value) {
  if(value < 10) {
    return '0'+value
  } else {
    return value
  }
}

function format_time(dt, hour, minute, second) {
  let formatted = ""
  let meridiem = ""
  switch(dt.time_format) {
    case "24-hour":
      formatted = pad(hour) + ':' + pad(minute)
      break;
    case "12-hour":
      if(hour < 12) {
        meridiem = 'am'
      } else if(hour == 12) {
        meridiem = 'pm'
      } else {
        meridiem = 'pm'
        hour = hour - 12
      }
      formatted = hour + ':' + pad(minute) + meridiem
      break;
    case "french":
      formatted = hour + 'h' + pad(minute)
      break;
    default:
      formatted = ""
  }
  return formatted
}

function format_date(dt, year, month, day) {
  let formatted = ""
  if (year == 0 || month == 0 || day == 0) {
    return formatted
  }
  switch(dt.date_format) {
    case "day-first":
      formatted = day + ' ' + month_names[month - 1]
      break;
    case "month-first":
      formatted = month_names[month - 1] + ' ' + day
      break;
    case "numeric-standard":
      formatted = pad(month) + '/' + pad(day)
      break;
    case "numeric-inverse":
      formatted = pad(day) + '/' + pad(month)
      break;
    default:
      formatted = ""
  }
  return formatted
}
