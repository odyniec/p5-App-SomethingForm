(function () {

if (!$ && jQuery) $ = jQuery;

$.extend($.fn, {
    somethingform: function (options) {
        if (!options) options = {};
    
        $(this).on('submit', function (event) {
            var form = this;
            var fieldsetNames = {};

            /* Map field names to containing fieldset names */
            $('input, textarea', form).map(function () {
                fieldsetNames[$(this).attr('name')] =
                    $(this).closest('fieldset', form).attr('name') ||
                    /* If the fieldset has no name, try <legend> */
                    $(this).closest('fieldset', form).find('legend').text();
            });

            var serializedData = $(form).serializeArray();
            var data = [];

            $.each(serializedData, function (i, field) {
                var fieldsetName = fieldsetNames[field['name']]

                /* Is this the first time that this fieldset appears? */
                if (!data.length || data[data.length-1][fieldsetName] === undefined) {
                    data[data.length] = {};
                    data[data.length-1][fieldsetName] = [];
                }

                data[data.length-1][fieldsetName].push(field);
            });

            $.ajax({
                type: 'POST',
                url: options['url'] || '/somethingform',
                data: JSON.stringify(data),
                contentType: 'text/plain',
                dataType: 'json',
                error: function (xhr, type) {
                    var requestError;
                    try {
                        requestError = JSON.parse(xhr.responseText).error;
                    } catch (err) {
                        requestError = err;
                    }

                    if (options.onError) {
                        options.onError.call();
                    }
                },
                success: function (resp) {
                    if (options.onSuccess) {
                        options.onSuccess.call();
                    }
                },
                complete: function () {
                    form.reset();
                }
            });

            event.preventDefault();
            return false;
        });
    }
});

})();
