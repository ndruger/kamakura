"use strict"
$(document).ready(->
  DELAY = 100;

  $('button').on('click', ->
    Q.delay(DELAY).then(->
      $(document.body).append($('<div>').attr(
        'class': 'result_text'
      ).css({
        'display': 'inline-block'
      }))
      Q.delay(DELAY)
      
    ).then(->
      $('.result_text').text('pushed')
      Q.delay(DELAY)

    )
  )
)