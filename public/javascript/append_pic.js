function clear_uuid() {
  SetCookie('pvuid', '');
}

function append_data(data, funcen) {
  var txt;
  if (funcen[0] == '1') {
    txt = 'Similar Items:';
    append_items('pfp', txt, JSON.parse(data.pkp));
  }
  if (funcen[1] == '1') {
    txt = 'People who like this also like:';
    append_items('pup', txt, JSON.parse(data.pup));
  }
  if (funcen[2] == '1') {
    txt = 'I guess you like these:';
    append_items('ufp', txt, JSON.parse(data.ukp));
  }
  if (funcen[3] == '1') {
    txt = 'People like you also like these:';
    append_items('ugp', txt, JSON.parse(data.ugp));
  }
  if (funcen[4] == '1') {
    txt = 'Hybrid Recommend:';
    append_items('all', txt, JSON.parse(data.all));
  }
  host = JSON.parse(data.pkp)[0].host;
  record_accepted(host);
}


function append_items(tabName, tabTitle, items) {
  var idx = 0;
  var rdx = 0;
  var row = $('<tr id='+tabName+'_'+rdx+'></tr>');
  var arrow_l = $('<a class="pvarrow pva_left" id='+tabName+'_l></a>')
  var arrow_r = $('<a class="pvarrow pva_right" id='+tabName+'_r></a>')
  var idx_max = 5; // window.innerWidth / 150;
  page_max = Math.ceil(items.length/idx_max);
  var pagin = $('<span class=pvpagein>Page <span id='+tabName+'_cpn>'+1+'</span> of '+page_max+'</span><br><hr class="pvhr">');
  var table = $('<table class=pvtable id='+tabName+' align=center>');
  for(i=0; i<items.length; i++){
    var txt  = items[i].title.substr(0, 20) + ((items[i].title.length > 20) ? "..." : "") + '('+items[i].count+')';
    var pic  = (items[i].url.length > 0) ? items[i].thumb : (root + "/images/gift.jpg");
    var img  = $('<img src=' + pic + ' width=80% ><p></p>').text(txt);
    var cat  = $('<b class=pvtitle>'+tabTitle+'</b>');
    if (is_demo) {
      var link_txt = 'href="/' + items[i].host + '/suggest?page=' + items[i]._id + '" src="' + items[i].url + '"';
    } else {
      var link_txt = 'href="/' + items[i].url + '"';
    }
    var link = $('<a class="pvitem" ' + link_txt + '></a>').append(img);
    var col  = $('<td></td>');
    col.append(link);
    row.append(col);
    idx ++;
    if ((idx == idx_max)||(i == items.length-1)) {
      table.append(row);
      rdx += 1;
      row = $('<tr id='+tabName+'_'+rdx+'></tr>');
      idx = 0;
    }
  }
  var wrapper = $("<div class=pvwrapper></div>").append(cat).append(pagin).append(arrow_l).append(table).append(arrow_r)
  $('#recommend_region').append(wrapper).append('<hr>');
  start_recommend(rdx, tabName);
}

function start_recommend(maxRow, tabName) {
  var sdx=0;
  var period=4000;
  var t;
  
  function recMove(forward){
    for(var i=0; i<maxRow; i++){
      $("#"+tabName+'_'+i).attr("style", "display:none;");
    }
    if(forward) {
      sdx = (sdx == maxRow-1) ? 0 : (sdx + 1);
    } else {
      sdx = (sdx == 0) ? maxRow-1 : (sdx - 1);
    }
    $("#"+tabName+'_'+sdx).attr("style", "");
    $("#"+tabName+'_cpn').text(sdx+1);
  }
  
  function start() {t = setInterval(function() {recMove(true);}, period);}
  $("#recommend_region").mouseover(function() {clearInterval(t);});
  $("#recommend_region").mouseleave(function() { start(); });
  $("#"+tabName+"_l").click(function() { recMove(false); }); 
  $("#"+tabName+"_r").click(function() { recMove(true); });
  start();
  for(var i=1; i<maxRow; i++){
    $("#"+tabName+'_'+i).attr("style", "display:none;");
  }
}

function record_accepted(host) {
  $(".pvitem").click(function(e) {
    var source = is_demo ? $(this).attr('src') : $(this).attr('href').substr(1,-1);
    var target = root + $(this).attr('href');
    console.log("pvitem clicked!" + host + '/' + source);
    $.ajax({
      data: {
        host:   host,
        target: source,
        user:   getCookie("pvuid")
      },
      dataType:"jsonp",
      url: root + "/api/accept",
      success: function(data) {
        window.location = target;
      }
    });
    e.preventDefault();
  });
}
