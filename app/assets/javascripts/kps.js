// калькулятор по позициям и итого
function calculate(val) {
  // console.log(val);
  var table_lines = $('#kp_products tbody tr'); // это нужно чтобы ошибки не выскакивали в js
  if (table_lines.length >= 1) {
    for (var i = 0; i < table_lines.length; i++) {
      var row = table_lines[i];
      //console.log(row);
      var quantity = row.cells[4].firstChild.firstChild.value;
      var price = row.cells[5].firstChild.firstChild.value;
      var sum = quantity * price;
      row.cells[6].firstChild.firstChild.value = sum.toFixed(2);
    };
    var rows = $("tr.nested-fields:visible");
    var tot = 0;
    for (var i = 0; i < rows.length; i++) {
      var row = rows[i];
      var sum = row.cells[6].firstChild.firstChild;
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


//создаём товар кп после добавления строки чтобы можно было потом редактировать описание
function create_kp_product(node_index) {
  //console.log("edit_kp create_kp_product",$('.edit_kp'));
  var kp_id = $('.edit_kp').attr('id').split("_").pop();
  $.ajax({
    type: "POST",
    url: '/kp_products',
    data: { kp_product: { kp_id: kp_id, desc: '', quantity: 0, price: 0 } },
    success: function(data){
      //console.log('success => ', data);
      var kp_pr_id = data.id;
      console.log('kp_pr_id', kp_pr_id);
      $("#kp_products tbody").append('<input type="hidden" value="'+kp_pr_id+'" name="kp[kp_products_attributes]['+node_index+'][id]" id="kp_kp_products_attributes_'+node_index+'_id">')
      $("#desc-wrap- a").attr("href", "/kp_products/"+kp_pr_id+"/update_modal");
      $("#desc-wrap-").attr("id", "desc-wrap-"+kp_pr_id);
    }
  });
}

//обновляем товар кп после автовыбора чтобы можно было потом редактировать описание
function update_kp_product(kp_id, product_id) {
  //console.log("edit_kp create_kp_product",$('.edit_kp'));
  $.ajax({
    type: "PUT",
    url: '/kp_products/'+kp_id,
    data: { kp_product: { product_id: product_id } },
    success: function(data){
      console.log('success update_kp_product => ', data);
    }
  });
}
//удаляем товар кп
function delete_kp_product( kp_product_id ) {
  //console.log("edit_kp create_kp_product",$('.edit_kp'));
  $.ajax({
    type: "DELETE",
    url: '/kp_products/'+kp_product_id,
    success: function(data){
      console.log('success delete_kp_product ', data);
    }
  });
}

// //автокомплит init после вставки строки
// function initLine() {
//   var idNode;

//   $("#kp_products")
//     .on('cocoon:before-insert', function(e, insertedItem) {
//       var row = insertedItem;
//       //console.log(row.find.attr('id'));
//       //console.log("function initLine row - "+row);
//       idNode = row.children('td').children([0]).children([0]).attr('id');
//       // console.log("function initLine idNode - "+idNode);
//     })
//     .on('cocoon:after-insert', function(e, insertedItem) {
//       //console.log("idNode => ",idNode);
//       console.log('============================');
//       console.log("insertedItem => ", insertedItem);
//       $("input[id = '" + idNode.replace("product_title", "quantity") + "']").val("0");
//       $("input[id = '" + idNode.replace("product_title", "price") + "']").val("0");
      
//       var node_index = idNode.replace("kp_kp_products_attributes_", "").replace("_product_title", "")
//       var check_input_present = $('input#kp_kp_products_attributes_'+node_index+'_id');
//       console.log('check_input_present.length', check_input_present.length);
//       if (check_input_present.length ) {
//         console.log('уже вставилась строка ране');
//         console.log('нажимается несколько раз автоматом');
//       } else {
//         create_kp_product(node_index);
//       }
      
//       calculate();
//     });
// }

// убираем значение id продукта пока не выберем следующий продукт
function getId(val) {
  var idNode = val;
   console.log("function getId idNode - "+idNode);
  $("input[id = '" + idNode.replace("product_title", "product_id") + "']").val('');
}

/* автокомплит */
function productAutocomplete(val){
  var idNode = val;
  $("input[id = '" + idNode + "']").bind('railsAutocomplete.select', function(event, data) {
    // console.log($(this).attr('id'));
    // console.log(idNode);
    console.log('railsAutocomplete.select => ', data);

    /* проставляем значения id продукта, кол-во продукта, цена продукта - если выберем продукт из списка продуктов  */
    var dataTitle = data.item.title;
    var dataId = data.item.id;
    var dataPrice = data.item.price;
    var dataDesc = data.item.desc;
    var dataSku = data.item.sku;
    $("input[id = '" + idNode + "']").val(dataTitle);
    $("input[id = '" + idNode.replace("product_title", "product_id") + "']").val(dataId);
    $("input[id = '" + idNode.replace("product_title", "quantity") + "']").val("1");
    $("input[id = '" + idNode.replace("product_title", "price") + "']").val(dataPrice);
    $("[id = '" + idNode.replace("product_title", "desc") + "']").val(dataDesc);
    console.log( 'productAutocomplete tr => ', $(this).closest('tr') );
    $(this).closest('tr').find(".desc").text(dataDesc.slice(0, 15) + '...');
    $(this).closest('tr').find(".desc").data('bsContent', dataDesc);
    $("[id = '" + idNode.replace("product_title", "sku") + "']").val(dataSku);
    var input = $("input[id = '" + idNode.replace("product_title", "id") + "']")
    var kp_id = $("input[id = '" + idNode.replace("product_title", "id") + "']").val();//$(this).closest('tr').attr('id').replace("nested-fields-", "");
    console.log('kp_id', kp_id);
    update_kp_product(kp_id, dataId);

    calculate();
  });
}

$(document).ready(function() {

  //productAutocomplete();
  calculate();
//автокомплит init после вставки строки

  $("#kp_products")
    .on('cocoon:before-insert', function(e, insertedItem) {
      var row = insertedItem;
      //console.log(row.find.attr('id'));
      //console.log("function initLine row - "+row);
      idNode = row.children('td').children([0]).children([0]).attr('id');
      //console.log("before-insert idNode - "+idNode);

    })
    .on('cocoon:after-insert', function(e, insertedItem) {
      // console.log('============================');
       console.log("insertedItem => ", insertedItem);
       console.log("insertedItem atr id => ", insertedItem[0].id);

      $("input[id = '" + idNode.replace("product_title", "quantity") + "']").val("0");
      $("input[id = '" + idNode.replace("product_title", "price") + "']").val("0");
      
      var node_index = idNode.replace("kp_kp_products_attributes_", "").replace("_product_title", "");
      insertedItem[0].id = 'nested-fields-'+node_index

      create_kp_product(node_index);
      
      calculate();
    });


  // пересчет суммы при удалении позиции из перечня товаров в исходящем счете
  $("#kp_products").children('tbody')
    .on('cocoon:before-remove', function(e, removeRow) {
      console.log( 'before-remove removeRow => ', removeRow.find('input')[0]);
      console.log( 'before-remove removeRow => ', removeRow.find('input')[0].id );
      // console.log( 'before-remove tr => ', $(this).closest('tr') );
      // console.log( 'before-remove tr context.firstElementChild => ', $(this).closest('tr').context.firstElementChild.dataset   );
      // var kp_id = $(this).closest('tr').context.firstElementChild.dataset.kpPId;
      //idNode = removeRow.children('td').children([0]).children([0]).attr('id');
      idNode = removeRow.find('input')[0].id;
      console.log(idNode);
      var input_id = idNode.replace("_image", "_id");
      $(this).data('remove-timeout', 1000);
      var input = $('#'+input_id).remove();
      var kp_product_id = input.val();
      input.remove();
      removeRow.fadeOut('slow');
      delete_kp_product( kp_product_id );
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
    // console.log("extraValue " + extraValue);
    var table_lines = $('#kp_products tbody tr');
    var total = $('#kp-total').text();
    // console.log("total " + total);
    var value = ((parseFloat(extraValue) + parseFloat(total)) / parseFloat(total)).toFixed(3);
    // console.log("value " + value);
    if (table_lines.length >= 1) {
      for (var i = 0; i < table_lines.length; i++) {
        var row = table_lines[i];
        //console.log(row);
        var price = row.cells[5].firstChild.firstChild.value;
        var newPrice = parseFloat(price) * value ;//(parseFloat(price) * value) / 100 + parseFloat(price);
        row.cells[5].firstChild.firstChild.value = newPrice.toFixed(0);
      };
    }
    calculate();
  });



  $('.custom-file-input').change(function(e){
    // console.log('e', e)
    var fileName = e.target.files[0].name;
    // console.log('fileName => ', fileName);
    // console.log('target => ', e.currentTarget['id']);
    $(`.custom-file-label[for=${e.currentTarget['id']}]`).html(fileName);
    $(`.custom-file-label[for=${e.currentTarget['id']}]`).show();
  });


});

