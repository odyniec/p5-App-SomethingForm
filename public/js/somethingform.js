(function () {

if (!$ && jQuery) $ = jQuery;

window.SomethingForm = {};
window.SomethingForm.formSpec = function (form) {
    var $fields = $('button,input,select,textarea', form);
    var spec = {};

    $fields.each(function (i) {
        if ($(this).is('button')) {
            if ($(this).attr('type') !== 'submit')
                return;
        }

        var name = $(this).attr('name');

        // Ignore unnamed controls
        if (name === undefined) return;
        // Ignore form signature
        if (name == 'somethingform_signature') return;
        // Ignore form metadata
        if (name == 'somethingform_metadata') return;

        spec[name] = {};

        if ($(this).is('input')) {
            //if ($(this).attr('type'))

            spec[name]['type'] = $(this).attr('type');
        }

        spec[name]['required'] = this.hasAttribute('required');
    });

    return spec;
}

$.extend($.fn, {
    somethingform: function (options) {
        if (!options) options = {};
    
        /* Add a submit event handler to each form */
        $(this).filter('form').on('submit', function (event) {
            var form = this;
            var fieldsetNames = {};

            /* Map field names to containing fieldset names */
            $('input, textarea', form).map(function () {
                var name = $(this).attr('name');

                if (name === undefined) return;

                if (name.match(/^somethingform_/))
                    fieldsetNames[name] = '_';
                else
                    fieldsetNames[name] =
                        $(this).closest('fieldset', form).attr('name') ||
                        /* If the fieldset has no name, try <legend> */
                        $(this).closest('fieldset', form).find('legend').text();
            });

            var serializedData = $(form).serializeArray();
            var data = [];

            $.each(serializedData, function (i, field) {
                var fieldsetName = fieldsetNames[field['name']];

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
