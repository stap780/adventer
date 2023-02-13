function check_first_page() {
  var vars = {};
  var x = document.location.search.substring(1).split('&');
  for (var i in x) {
    var pagetype = x[i].split('=', 2);
    vars[pagetype[0]] = decodeURIComponent(pagetype[1]);
    // var pagetype_text = document.createTextNode(x[i]);
    // document.getElementById("pdf_console_output").appendChild(pagetype_text);
    // document.getElementById("pdf_console_output").style.display = 'block';
  }
  var vars_text = document.createTextNode(vars['page']);
  document.getElementById("pdf_console_output").appendChild(vars_text);
  document.getElementById("pdf_console_output").style.display = 'block';

  var pagenumber = vars_text
  if (pagenumber == 1) {
    document.getElementsByClassName("headerContent")[0].style.display = "none";
  }
}

function number_pages() {
  console.log('hi');
  var vars = {};
  var x = document.location.search.substring(1).split('&');
  console.log(x);
  for (var i in x) {
    var z = x[i].split('=', 2);
    console.log(z);
    vars[z[0]] = decodeURIComponent(z[1]);
  }
  var x = ['frompage', 'topage', 'page', 'webpage', 'section', 'subsection', 'subsubsection'];
  for (var i in x) {
    var y = document.getElementsByClassName(x[i]);
    console.log(y);
    for (var j = 0; j < y.length; ++j) y[j].textContent = vars[x[i]];
  }
  var pagenumber = vars['page'];
  var header = document.getElementsByClassName("headerContent")[0];
  var headerHeight = header.offsetHeight;
  var headerWidth = header.offsetWidth;
  // if (pagenumber == 1 || pagenumber == 2) {
  //   document.getElementsByClassName("headerContent")[0].style.display = "none";
  //   document.getElementsByClassName("footerContent")[0].style.display = "none";
  // }
  if (pagenumber == 1) {
    document.getElementById('header_height').innerText = headerHeight;
    document.getElementById('header_width').innerText = headerWidth;
  }

  if (pagenumber == 2) {
    header.style.display = "none";
    document.getElementsByClassName("footerContent")[0].style.display = "none";
  }


}

function loadPage() {
  document.getElementById('status').style.display = 'block';

  document.getElementById("pdf_console_output").style.display = 'block';
  document.getElementById("pdf_console_output").style.color = 'blue';
  var text = document.createTextNode(" - This just got added - ");
  document.getElementById("pdf_console_output").appendChild(text);

  var x = document.location.search.substring(1).split('&');
  for (var i in x) {
    var pagetype = x[i].split('=', 2);
    var pagetype_text = document.createTextNode(pagetype);
    document.getElementById("pdf_console_output").appendChild(pagetype_text);
  }
}
;
