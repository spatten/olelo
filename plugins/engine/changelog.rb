description 'Changelog Engine'
dependencies 'engine/engine'
require     'rss/maker'

Engine.create(:changelog, :cacheable => true, :hidden => true) do
  def output(context)
    page, format = context.page, context.params[:format]

    url = context.request.url_without_path
    context.response['Content-Type'] = "application/#{format == 'rss' ? 'rss' : 'atom'}+xml; charset=utf-8"

    content = RSS::Maker.make(format == 'rss' ? '2.0' : 'atom') do |feed|
      feed.channel.generator = 'Ōlelo'
      feed.channel.title = Config.title
      feed.channel.link = url + page.path
      feed.channel.description = Config.title + ' Changelog'
      feed.channel.id = url + page.path
      feed.channel.updated = Time.now
      feed.channel.author = Config.title
      feed.items.do_sort = true
      page.history.each do |version|
        i = feed.items.new_item
        i.title = version.comment
        i.link = url + 'changes'/version
        i.date = version.date
        i.dc_creator = version.author.name
      end
    end
    content.to_s
  end
end

Application.hook :render do |name, xml, layout|
  if layout
    xml.sub!('</head>', %{<link rel="alternate" type="application/atom+xml" title="Sitewide Atom Changelog"
                          href="#{escape_html absolute_path('/', :output => 'changelog', :format => 'atom')}"/>
                          <link rel="alternate" type="application/rss+xml" title="Sitewide RSS Changelog"
                          href="#{escape_html absolute_path('/', :output => 'changelog', :format => 'rss')}"/></head>}.unindent)
    xml.sub!('</head>', %{<link rel="alternate" type="application/atom+xml" title="#{escape_html page.path} Atom Changelog"
                          href="#{escape_html(absolute_path(page, :output => 'changelog', :format => 'atom'))}"/>
                          <link rel="alternate" type="application/rss+xml" title="#{escape_html page.path} RSS Changelog"
                          href="#{escape_html(absolute_path(page, :output => 'changelog', :format => 'rss'))}"/></head>}.unindent) if page && !page.new? && !page.root?
  end
end
