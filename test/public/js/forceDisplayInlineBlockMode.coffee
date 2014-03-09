"use strict"
$(document).ready(->
  DELAY = 100;

  $('button').on('click', ->
    Q.delay(DELAY).then(->
      $(document.body).append($('<div>').attr(
        'class': 'result_text'
      ).css(
        'display': 'none'
      ).text('pushed'))
      Q.delay(DELAY)
    ).then(->
      Q.delay(DELAY)

    )
  )
)