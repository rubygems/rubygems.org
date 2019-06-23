$(document).on('turbolinks:load', function(){
    $(document).on('keyup', '#form', function(e){
    e.preventDefault();
    var input = $.trim($(this).val());
    $.ajax({ //ajax通信で以下のことを行います
      url: '/search', //urlを指定
      type: 'GET', //メソッドを指定
      data: ('keyword=' + input), //コントローラーに渡すデータを'keyword=input(入力された文字のことですね)'にするように指定
      processData: false, //おまじない
      contentType: false, //おまじない
      dataType: 'json' //データ形式を指定
    })
  });
});
