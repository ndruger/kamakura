$(document).ready(->
  DELAY = 100;

  $('button').on('click', ->
    Q.delay(DELAY).then(->
      $(document.body).append($('<div>').attr(
        'class': 'result'
      ))
      Q.delay(DELAY)
      
    ).then(->
      $('.result').text('pushed')
      Q.delay(DELAY)

    )
  )
)