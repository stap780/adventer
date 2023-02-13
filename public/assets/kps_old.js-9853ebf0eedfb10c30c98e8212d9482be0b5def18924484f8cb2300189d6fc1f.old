// калькулятор по позициям и итого
function calculate(val) {
  // console.log(val);
  var table_lines = $('#kp_products tbody tr'); // это нужно чтобы ошибки не выскакивали в js
  if (table_lines.length >= 1) {
    for (var i = 0; i < table_lines.length; i++) {
      var row = table_lines[i];
      //console.log(row);
      var quantity = row.cells[1].firstChild.firstChild.value;
      var price = row.cells[2].firstChild.firstChild.value;
      var sum = quantity * price;
      row.cells[3].firstChild.firstChild.value = sum.toFixed(2);
    };
    var rows = $("tr.nested-fields:visible");
    var tot = 0;
    for (var i = 0; i < rows.length; i++) {
      var row = rows[i];
      var sum = row.cells[3].firstChild.firstChild;
      if (parseFloat(sum.value))
        tot += parseFloat(sum.value);
    }
    // var discount = document.getElementById("invoice_discount");
    // var delivery = $('.delivery').html();
    // if (parseInt(discount.value) > "0") {
    //   var newtot = tot - tot * parseFloat(discount.value) / 100;
    //   document.getElementById('invoice_total_price').value = newtot.toFixed(2);;
    // } else {
    //   document.getElementById('invoice_total_price').value = tot.toFixed(2);;
    // }
    $('#kp-total').html(tot.toFixed(2));
  }
};
//

//автокомплит init после вставки строки
function initLine() {
  var id;
  var dataId;
  //alert('hi');
  $("#kp_products")
    .on('cocoon:before-insert', function(e, insertedItem) {
      var row = insertedItem;
      //console.log(row.find.attr('id'));
      //console.log("function initLine row - "+row);
      idNode = row.children('td').children([0]).children([0]).attr('id');
      // console.log("function initLine id - "+id);
    })
    .on('cocoon:after-insert', function(e, insertedItem) {
      $("input[id = '" + idNode.replace("product_sku_title", "quantity") + "']").val("0");
      $("input[id = '" + idNode.replace("product_sku_title", "price") + "']").val("0");
      calculate();
    });
     // автокомплит для строк что создаются динамически
    // .bind('railsAutocomplete.select', function(event, data) {
    //   console.log(data);
    //   dataId = data.item.id;
    //   dataValue = data.item.value;
    //   dataPrice = data.item.price;
    //   //$("input[id='" + idNode + "']").val(dataValue);
    //   $("input[id = '" + idNode.replace("product_sku_title", "product_id") + "']").val(dataId);
    //   $("input[id = '" + idNode.replace("product_sku_title", "quantity") + "']").val("1");
    //   $("input[id = '" + idNode.replace("product_sku_title", "price") + "']").val(dataPrice);
    //   calculate();
    // });
}

// убираем значение id продукта пока не выберем следующий продукт
function getId(val) {
  var idNode = val;
  // console.log("function getId idNode - "+idNode);
  $("input[id = '" + idNode.replace("product_sku_title", "product_id") + "']").val('');
}

function productAutocomplete(val){
  var idNode = val;
  $("input[id = '" + idNode + "']").bind('railsAutocomplete.select', function(event, data) {
    /* Do something here */
    // console.log($(this).attr('id'));
    console.log(event);
    // console.log(data.item);

    // проставляем значения id продукта, кол-во продукта, цена продукта - если выберем продукт из списка продуктов
    var dataId = data.item.id;
    var dataPrice = data.item.price;
    $("input[id = '" + idNode.replace("product_sku_title", "product_id") + "']").val(dataId);
    $("input[id = '" + idNode.replace("product_sku_title", "quantity") + "']").val("1");
    $("input[id = '" + idNode.replace("product_sku_title", "price") + "']").val(dataPrice);
    calculate();
  });
}

$(document).ready(function() {

  calculate();

  // пересчет суммы при удалении позиции из перечня товаров в исходящем счете
  $("#kp_products").children('tbody')
    .on('cocoon:before-remove', function(e, task) {
      $(this).data('remove-timeout', 1000);
      task.fadeOut('slow');
    })
    .on('cocoon:after-remove', function(e, removeRow) {
      //console.log($(this));
      // var row = removeRow;
      //console.log(row);

      calculate();
    });

  // пересчет суммы при изменении поля extra
  $("#kp_extra").on('change', function() {
    var extraValue = $(this).val();
    console.log("extraValue " + extraValue);
    var table_lines = $('#kp_products tbody tr');
    var total = $('#kp-total').text();
    console.log("total " + total);
    var value = ((parseFloat(extraValue) + parseFloat(total)) / parseFloat(total)).toFixed(3);
    console.log("value " + value);
    if (table_lines.length >= 1) {
      for (var i = 0; i < table_lines.length; i++) {
        var row = table_lines[i];
        //console.log(row);
        var price = row.cells[2].firstChild.firstChild.value;
        var newPrice = parseFloat(price) * value ;//(parseFloat(price) * value) / 100 + parseFloat(price);
        row.cells[2].firstChild.firstChild.value = newPrice.toFixed(2);
      };
    }
    calculate();
  });

  // автокомплит для строк которые уже есть в таблице
  // $('input.autocomplete').bind('railsAutocomplete.select', function(event, data) {
  //   /* Do something here */
  //   // console.log($(this).attr('id'));
  //   // console.log(event);
  //   // console.log(data.item);
  //   var idNode = $(this).attr('id');
  //   // проставляем значения id продукта, кол-во продукта, цена продукта - если выберем продукт из списка продуктов
  //   var dataId = data.item.id;
  //   var dataPrice = data.item.price;
  //   $("input[id = '" + idNode.replace("product_sku_title", "product_id") + "']").val(dataId);
  //   $("input[id = '" + idNode.replace("product_sku_title", "quantity") + "']").val("1");
  //   $("input[id = '" + idNode.replace("product_sku_title", "price") + "']").val(dataPrice);
  //   calculate();
  // });

});
