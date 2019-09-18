//data page
$(document).ready(function() {
  var getDumpData = function(target, type) {
    return $.get('https://s3-us-west-2.amazonaws.com/rubygems-dumps/?prefix=production/public_' + type).done(function(data) {
      var files, xml;
      xml = $(data);
      files = parseS3Listing(xml);
      files = sortByLastModified(files);
      $(target).html(renderDumpList(files));
    }).fail(function(error) {
      console.error(error);
    });
  };

  var parseS3Listing = function(xml) {
    var files;
    files = $.map(xml.find('Contents'), function(item) {
      item = $(item);
      return {
        Key: item.find('Key').text(),
        LastModified: item.find('LastModified').text(),
        Size: item.find('Size').text(),
        StorageClass: item.find('StorageClass').text()
      };
    });
    return files;
  };

  var sortByLastModified = function(files) {
    return files.sort(function(a, b) {return Date.parse(b.LastModified) - Date.parse(a.LastModified)});
  };

  var bytesToSize = function(bytes) {
    var i, k, sizes;
    if (bytes === 0) {
      return '0 Byte';
    }
    k = 1024;
    sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    i = Math.floor(Math.log(bytes) / Math.log(k));
    return (bytes / Math.pow(k, i)).toPrecision(3) + " " + sizes[i];
  };

  var renderDumpList = function(files) {
    var content;
    content = [];
    jQuery.each(files, function(idx, item) {
      if ('STANDARD' === item.StorageClass) {
        return content.push("<li><a href='https://s3-us-west-2.amazonaws.com/rubygems-dumps/" + item.Key + "'>" + (item.LastModified.replace('.000Z', '')) + " (" + (bytesToSize(item.Size)) + ")</a></li>");
      }
    });
    return content.join("\n");
  };

  if($("#data-dump").length) {
    getDumpData('ul.rubygems-dump-listing-postgresql', 'postgresql');
    getDumpData('ul.rubygems-dump-listing-redis', 'redis');
  }
});

//stats page
$('.stats__graph__gem__meter').each(function() {
  bar_width = $(this).data("bar_width");
  $(this).animate({ width: bar_width + '%' }, 700).removeClass('t-item--hidden');
});

//gem page
$(document).ready(function() {
  $('.gem__users__mfa-text.mfa-warn').on('click', function() {
    $('.gem__users__mfa-text.mfa-warn').toggleClass('t-item--hidden');

    $owners = $('.gem__users__mfa-disabled');
    $owners.toggleClass('t-item--hidden');
  });
});
