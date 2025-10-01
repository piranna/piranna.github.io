---
layout: post
tags: web, html, canvas, video, webrtc, webvtt, webm, metadata
title: How to paint over a video with HTML
twitter: '1332171837019709441'
---

I recently got to work on a project where I need to capture a camera, sendback
some drawed feedback, exchange commands and chat messages (and voice comments),
and record everything. I've always been interested on using non-mainstream
features of the Web Platform, and after taking a look of the current
*state of the art*, I've found a way to implement this particular use case using
ONLY open and readily available web standards.

Sometimes, when you left out social networks and embrace back the Internet 90's
spirit, you find yourself rediscovering that the Web is still an amazing place
:-)

## Canvas recording

[Canvas](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/canvas)
element has by default a transparent background, allowing it to be used as an
overlay over other elements, for example a
[Video](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/video)
element. In addition to that, `Canvas` provides the
[captureStream](https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/captureStream)
method, that generates a
[MediaStream](https://developer.mozilla.org/en-US/docs/Web/API/MediaStream) with
all the `Canvas` changes and drawing. By combining both concepts, we can be able
to "paint" over a video (or any other HTML element) and record the changes
without modifying the original.

## Send stream

This `MediaStream` can be send over a [WebRTC](https://webrtc.org/) connection
to a Media Server, or to another WebRTC client, like a web browser. The main
drawback is that videos with alpha channel are only available for
[VP8](http://tools.ietf.org/html/rfc6386)/
[VP9](https://www.webmproject.org/vp9) codecs and the upcoming
[AV1](https://aomedia.org/av1-features/), that are available only with
[WebM](https://www.webmproject.org/) (a subset of
[Matroska](https://www.matroska.org)) containers, lefting
[MP4](https://stackoverflow.com/a/55157224/586382) and H264 out. Both VP8/VP9
codecs and `WebM` containers are supported by all main browsers since their
support are mandatory by `WebRTC` specification, so there would not be any
problem to codec and stream the videos, but since for them there's no hardware
aceleration available, for reproduction there could be some situations like
[Apple doesn't support WebM outside a WebRTC context](https://caniuse.com/webm)
(as usual, [Safari is the new IE6](https://www.safari-is-the-new-ie.com/)), and
it would need to have the video
[in a different format](https://stackoverflow.com/a/63607750/586382).

## Inline metadata

[WebVTT](https://www.w3.org/TR/webvtt1/) is a web standard to add cue
(subtitles) to the videos in the web that can also to be
[styled with CSS](https://developer.mozilla.org/en-US/docs/Web/Guide/Audio_and_video_delivery/Adding_captions_and_subtitles_to_HTML5_video#Styling_the_displayed_subtitles)
for example for each one of the participants in a conversation, and includes
support for `metadata` cues that can be used to store information like
[GeoJSON info about the location of the streamer](http://wiki.webmproject.org/webm-metadata/temporal-metadata/webvtt-metadata)
or operations that are being done. Drawback is that there's no current
Javascript APIs to add the WebVTT tracks in the browser in the `MediaStream`
itself, although it has been considered as
[a future use case of WebRTC](https://stackoverflow.com/a/39581358/586382), so
currently they can not be send inline from the source and would need to be
out-of-band and added afterwards. The same happens with
[tracks names](https://www.webmproject.org/docs/container/#Name), that there's
no APIs to identify them inline from the source and
[would need to be mapped](https://superuser.com/a/1329070) based on their unique
`ìd`s once the video is already generated. That same mechanism can be used to
include additional metadata of the video itself, not only of its tracks.

## Videos storage

For videos storage, due to usage of videos with an alpha channel only currently
available option is to use WebM container, as already discussed. WebM has
support for multiple video tracks, so it's possible to store both the original
video and the `Canvas` overlayed one in the same container, and also allow to
add multiple WebVTT tracks to store the audio transcriptions, commands
operations, or metadata.

## Reproduction of combined videos

Finally, for reproduction, the multiple video tracks are extracted from the WebM
container and/or the WebRTC stream, and applied to multiple `Video` elements.
It's possible to define what video track to use on each one by using the
[videotracks](https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/videoTracks)
attribute of the `Video` element, but althought its support is very extended,
it's still a experimental feature that needs to be enabled explicitly, and where
most current implementations like Chrome one
[only show the first available video track](https://paul.kinlan.me/crbug-894556-multiple-video-tracks-in-a-mediastream-are-not-reflected-on-the-videotracks-object-on-the-video-element/).
Alternatively, it could be possible to extract the
[video tracks](https://developer.mozilla.org/en-US/docs/Web/API/MediaStream/getVideoTracks)
from the `MediaStream` and include them in new ad-hoc `MediaStream` objects,
mostly replicating by hand the `Video` element `videotracks` functionality (in
fact, it could be possible to write a polyfill, creating and returning a fixed
[VideoTrackList](https://developer.mozilla.org/en-US/docs/Web/API/VideoTrackList)
object). That would probably be the same
process needed to be done with Android or iOS clients, in case they don't
support selecting the video track. Once videos are extracted, it would be just a
matter of layout the `Video` elements with the `Canvas` alpha channel videos on
top of the other original one since they already support
[transparent videos](https://ataylor32.github.io/demo-html5-transparent-video/),
but alpha videos support for native Android and iOS APIs would need to be
investigated, or if not, then each frame would need to be painted by hand.
Additionally, it would be good to use the
[mediagroup](https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/mediaGroup)
attribute, although it's not clear what its current support status. Regarding
inline `WebVTT` tracks, it's not clear if they would be automatically extracted
and included by the `Video` element itself or if it would be needed to be send
out-of-band and included by using a
[Track element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/track)
but there's a [spec](https://dev.w3.org/html5/html-sourcing-inband-tracks/) with
the intention to provide a common Javascript mapping API between inline cues in
multiple container formats (including WebM).

## Other links

- https://jakearchibald.com/scratch/alphavid/
- https://developers.google.com/web/updates/2013/07/Alpha-transparency-in-Chrome-video
- https://caniuse.com/audiotracks
- https://blog.addpipe.com/10-advanced-features-in-html5-video-player/
- https://groups.google.com/a/webmproject.org/g/webm-discuss/c/v6ojc0Uu7wo/m/AG_0jwXZj2IJ
- https://www.anerbarrena.com/atributo-mediagroup-html5-5410/
- https://www.w3.org/WAI/PF/HTML/wiki/Media_Multitrack_Media_API
- https://www.webmproject.org/docs/container/
- http://wiki.webmproject.org/webm-metadata/temporal-metadata/webvtt-in-webm
