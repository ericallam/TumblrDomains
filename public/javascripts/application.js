$(document).ready(function(){
  $('#step_1 form').submit(function(e){
    e.preventDefault();
    var form = $(this);
    var domain_name = form.find('input#domain_name').val();

    $.getJSON(form.attr('action'), {'domain_name' : domain_name}, function(data, textStatus){
      if(data['available']){
        $('#step_1 .step_contents').slideUp('fast');
        $('#step_1 .step_headline').html(domain_name + ' is available!')
        $('#step_1 .success').show();
        $('#step_2 .step_contents').slideDown('fast');
        $('#step_2 input[name="domain"]').val(domain_name);
      }else{
        $('#step_1 .error').html(data['error']).show();
      }
    })

  });

  $('#step_2_b form').submit(function(e){
    e.preventDefault();

    var form = $(this);

    var tumblelog = form.find('select[name="tumblelog"]').val();

    $.post(
      form.attr('action')
      ,{'registration': {'tumblelog': tumblelog}}
      ,function(data, textStatus){
        if(data['success']){
          $('#step_2_b').slideUp('fast');
          $('#step_3 .step_contents').slideDown('fast');
          $('#payments_url').attr('href', data['payment_url'])
        }else{
        
        }
      }
      ,'json'
    )
  });

  $('#step_2 form:first').submit(function(e){
    e.preventDefault();

    var form = $(this);

    var email = form.find('input[name="email"]').val();
    var password = form.find('input[name="password"]').val();
    var domain = form.find('input[name="domain"]').val();

    $.post(
      form.attr('action')
      ,{'registration': {'email': email, 'password': password, 'domain': domain}}
      ,function(data, textStatus){
        console.log(data);

        if(data['success']){
          if(data['tumblelogs'].length > 1){
            // get them to choose the tumblelog, and then update the registration
            var bform = $('#step_2_b form')
            var select = bform.find('select[name="tumblelog"]');
            
            var options = $.map(data['tumblelogs'], function(entry, index){
              return '<option value="' + entry['name'] + '">' + entry['title'] + '</option>'
            });

            $.each(options, function(i, option){
              select.append(option);
            });

            $('#step_2 .step_contents').slideUp('fast');
            $('#step_2 .success').show();

            $('#step_2_b').show();


          }else{
            // go ahead to step 3, only one tumblelog to choose from
            $('#step_2 .step_contents').slideUp('fast');
            $('#step_2 .success').show();
            $('#step_3 .step_contents').slideDown('fast');
          }
        }else{
        
        }
      } 
      ,'json'
    );
  });
});
