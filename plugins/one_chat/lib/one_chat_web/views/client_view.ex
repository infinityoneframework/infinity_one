defmodule OneChatWeb.ClientView do
  use OneChatWeb, :view

  def page_loading do
    """
    <style>
      #initial-page-loading .loading-animation {
        background: linear-gradient(to top, #6c6c6c 0%, #aaaaaa 100%);
        z-index: 1000;
      }
      .loading-animation {
        top: 0;
        right: 0;
        left: 0;
        display: flex;
        align-items: center;
        position: absolute;
        justify-content: center;
        text-align: center;
        z-index: 100;
        height: 100% !important;
      }
      .loading-animation > div {
        width: 10px;
        height: 10px;
        margin: 2px;
        border-radius: 100%;
        display: inline-block;
        background-color: rgba(255,255,255,0.6);
        -webkit-animation: loading-bouncedelay 1.4s infinite ease-in-out both;
        animation: loading-bouncedelay 1.4s infinite ease-in-out both;
      }
      .loading-animation .bounce1 {
        -webkit-animation-delay: -0.32s;
        animation-delay: -0.32s;
      }
      .loading-animation .bounce2 {
        -webkit-animation-delay: -0.16s;
        animation-delay: -0.16s;
      }
      @-webkit-keyframes loading-bouncedelay {
        0%,
        80%,
        100% { -webkit-transform: scale(0) }
        40% { -webkit-transform: scale(1.0) }
      }
      @keyframes loading-bouncedelay {
        0%,
        80%,
        100% { transform: scale(0); }
        40% { transform: scale(1.0); }
      }
      .page-loading-container {
        position: absolute;
        top: 0; right: 0; left: 0; bottom: 0;
        z-index: 5000;
        background: black;
        opacity: 0.8;
      }
      .page-loading-container .loading-animation > div {
        background-color: #eee !important;
      }
      .loading-animation.light_on_dark {
        background-color: rgba(0,0,0,0.7);

        position: fixed;
        right: 40px;
        left: unset;
        bottom: 0;
        height: 100%;
        width: 400px;
      }
      .loading-animation.light_on_dark > div {
        background-color: #eee !important;
      }
    </style>
    """
  end
  def loadmore do
    ~s(<li class="load-more"></li>)
  end

  def loading_animation(class \\ :default) do
    """
    <div class="loading-animation #{class}">
      <div class="bounce1"></div>
      <div class="bounce2"></div>
      <div class="bounce3"></div>
    </div>
    """
    |> String.replace("\n", "")
  end

end
