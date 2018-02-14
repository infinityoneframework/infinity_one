console.log('loading file_upload_restrections');

UccChat.fileUploadMediaWhiteList = function() {
  var mediaTypeWhiteList = chat_settings.accepted_media_types
  if (!mediaTypeWhiteList || mediaTypeWhiteList === '*') {
    return;
  }
  return _.map(mediaTypeWhiteList.split(','), function(item) {
    return item.trim();
  });
};

UccChat.fileUploadIsValidContentType = function(type, whiteList) {
  var list, wildCardGlob, wildcards;
  if (whiteList) {
    list = whiteList;
  } else {
    list = UccChat.fileUploadMediaWhiteList();
  }
  console.log('white list', list)
  if (!list || _.contains(list, type)) {
    return true;
  } else {
    wildCardGlob = '/*';
    wildcards = _.filter(list, function(item) {
      return item.indexOf(wildCardGlob) > 0;
    });
    if (_.contains(wildcards, type.replace(/(\/.*)$/, wildCardGlob))) {
      return true;
    }
  }
  return false;
};
