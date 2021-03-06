RP = RP || {}

function doFitImage(evt) {
    fitImage(evt.target)
}

function onImageError(image) {
    image.onerror = "";
    if (image.alt && (image.alt.match(/\.(jpg|tif|tiff|gif|png)$/) != null)) {
        image.src = image.alt
    } else {
        image.src = "/assets/BadPicURL.png";
    }
    return true;
}

function fitImage(img) {

    if (!img) return false;

    var parent = img.parentElement, frameWidth, frameHeight, picWidth, picHeight;

    if (!(img.complete &&
        (img.width > 5) &&
        (img.height > 5) &&
        ((picWidth = img.naturalWidth) > 5) &&
        ((picHeight = img.naturalHeight) > 5) &&
        ((frameWidth = $(parent).width()) > 5) &&
        ((frameHeight = $(parent).height()) > 5)
        )) return false;

    var frameAR = frameWidth / frameHeight;
    var imgAR = picWidth / picHeight;
    var fillmode;
    if (fillmode = $(img).data("fillmode")) {
        if (fillmode == "width") {
            // Size image to fit parent's width
            $(img).css("width", frameWidth);
            $(img).css("height", frameWidth / imgAR);
        }
    } else {
        if (imgAR > frameAR) {
            var newHeight = frameWidth / imgAR;
            $(img).css("width", frameWidth);
            $(img).css("height", newHeight);
            // $(img).css("padding-left", 0);
            // $(img).css("padding-top", (frameHeight-newHeight)/2);
            // $(img).css("left", 0);
        } else {
            var newWidth = frameHeight * imgAR;
            $(img).css("width", newWidth);
            $(img).css("height", frameHeight);
            // $(img).css("top", 0);
            // $(img).css("padding-top", 0);
            // $(img).css("padding-left", (frameWidth-newWidth)/2);
        }
    }
    $(img).addClass("loaded")
    return true;
}

// Set the source for the preview image, only loading the form field when the image is successfully loaded
// NB: an empty image url is valid, and substituted in the image (but not in the form) with a fallback url
function set_image_safely(imageElmt, url, formsel) {
    var url_shown = url;
    if (url.length < 1) {  // Substitute empty url with placeholder for display purposes only
        url_shown = $(imageElmt).data('fallbackurl') || "/assets/NoPictureOnFile.png"
        $(imageElmt).addClass('empty')
    }
    $(imageElmt).removeClass('bogus') // Pending load attempt
    // Apply the display url to the preview, and save the form selector and actual URL pending successful load
    $(imageElmt).removeClass("loaded").attr("src", url_shown).data("formsel", formsel).data("url_actual", url)
    imgLoad = imagesLoaded(imageElmt);
    imgLoad.on('progress', function (instance, image) {
        var img = image.img
        if (image.isLoaded) {
            var formsel = $(img).data("formsel")
            $(img).addClass("loaded")
            $(formsel).attr("value", $(img).data("url_actual"))
        } else {
            $(img).addClass("bogus").removeClass("loaded")
            img.src = "/assets/BadPicURL.png"
        }
        $(image.img).trigger('ready')
    })
//	}
    return false;
}

// Copy an input URL to both the preview image and the (hidden) form field
function previewImg(inputsel, imagesel, formsel) {
    // Copy the url from the input field to the form field
    var url = $(inputsel).attr("value");

    // If not specified by the selector, the preview image is a sibling of the input element
    // var imageElmt = $(imagesel)[0] || $('img', inputElmt.parentElement)[0];
    // For display purposes we use a no-picture picture
    set_image_safely(imagesel, url, formsel);
    return false;
}

// Place an image URL into both a preview image  and an accompanying input field, if any
function imagePreviewWidgetSet(imgID, inputID, url) {
    set_image_safely("img#" + imgID, url, "input#" + inputID)
    return false;
}

// onload handler to validate image (since we can't use imagesLoaded for hardwired URLs)
RP.validate_img = function (event) {
    var img = event.target;
    if (img.complete) {
        // Normally this is the end of it, but we may have an image with no url,
        // in which case we want to report thus.
        if($(img).attr('src').length < 1) {
            // Empty URL: not a bad URL but still needs standin
            img.src = $(img).data('fallbackurl') || "/assets/NoPictureOnFile.png"
            $(img).addClass('bogus')
        }
    } else { // Loaded but not complete => error
        if(!$(img).hasClass("bogus")) {   // Replace url with invalid-image url if this is the first try
            $(img).addClass("bogus")
            if($(img).attr('src').length < 1) {
                // Empty URL: not a bad URL but still needs standin
                img.src = $(img).data('fallbackurl') || "/assets/NoPictureOnFile.png"
            } else // non-empty URL didn't load: report bad URL
                img.src = "/assets/BadPicURL.png";
        }
    }
}
