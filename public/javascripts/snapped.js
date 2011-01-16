var snapped = {
  setHotkeys: function() {
    $(document).bind('keydown', 'left',  snapped.navPrev);
    $(document).bind('keydown', 'j',     snapped.navPrev);
    $(document).bind('keydown', 'right', snapped.navNext);
    $(document).bind('keydown', 'k',     snapped.navNext);
  },
  
  navPrev: function() {
    var prev_link = $('.prev_link.enabled')[0];
    undefined == prev_link ? false : document.location = prev_link.href;
  },
  
  navNext: function() {
    var next_link = $('.next_link.enabled')[0];
    undefined == next_link ? false : document.location = next_link.href;
  }
  
}
