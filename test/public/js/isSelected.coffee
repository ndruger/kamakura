$(document).ready(->
  DELAY = 100;

  $('button').on('click', ->
    Q.delay(DELAY).then(->
      $('.result_select').val('result');
    )
  )
)