# frozen_string_literal: true

require "fileutils"
require "open3"
require "tempfile"

module MermaidImageFilter
  MERMAID_START = /\A\s*(flowchart|graph|sequenceDiagram|classDiagram|stateDiagram(?:-v2)?|erDiagram|journey|gantt|pie|mindmap|timeline|quadrantChart|xychart|block-beta|packet-beta|gitGraph|C4Context)\b/.freeze

  def self.prebuild_url(input, site)
    source = input.to_s
    return nil unless mermaid_source?(source)

    require "jekyll-mermaid-prebuild"

    config = site.data["mermaid_prebuild_config"] || JekyllMermaidPrebuild::Configuration.new(site)
    generator = site.data["mermaid_prebuild_generator"] || JekyllMermaidPrebuild::Generator.new(config)
    args = mermaid_cli_args(site)
    cache_key = JekyllMermaidPrebuild::DigestCalculator.content_digest(([source] + args).join("\0"))
    cache_path = File.join(config.cache_dir, "#{cache_key}.svg")

    unless File.exist?(cache_path)
      FileUtils.mkdir_p(config.cache_dir)
      return nil unless render_mermaid_svg(site, source, cache_path, args)

      generator.send(:post_process_svg, cache_path, root_background: config.chart_background_light)
    end

    site.data["mermaid_prebuild_enabled"] = true
    site.data["mermaid_prebuild_config"] = config
    site.data["mermaid_prebuild_generator"] = generator
    site.data["mermaid_prebuild_svgs"] ||= {}
    site.data["mermaid_prebuild_svgs"][cache_key] = cache_path

    generator.build_svg_url(cache_key)
  rescue LoadError, StandardError => error
    Jekyll.logger.warn "MermaidImage:", "Could not prebuild image: #{error.message}"
    nil
  end

  def mermaid_prebuild_url(input)
    MermaidImageFilter.prebuild_url(input, @context.registers[:site])
  end

  def self.mermaid_source?(source)
    source.include?("\n") && source.match?(MERMAID_START)
  end

  def self.normalize_item_image(item, site)
    image = item.data["image"]
    url = prebuild_url(image, site)
    return unless url

    item.data["image_mermaid"] = image
    item.data["image"] = url
  end

  def self.mermaid_cli_args(site)
    spaceship = site.config.fetch("jekyll-spaceship", {})
    mermaid = spaceship.fetch("mermaid-processor", {})
    Array(mermaid["mmdc_args"]).map(&:to_s)
  end

  def self.render_mermaid_svg(site, source, output_path, args)
    command = local_mmdc(site) || "mmdc"
    input = Tempfile.new(["hero-image", ".mmd"])

    begin
      input.write(source)
      input.close

      _stdout, stderr, status = Open3.capture3(
        command, "-i", input.path, "-o", output_path, "-e", "svg", *args
      )
      Jekyll.logger.warn "MermaidImage:", "mmdc failed: #{stderr.strip}" unless status.success?
      status.success?
    ensure
      input.close!
    end
  end

  def self.local_mmdc(site)
    executable = Gem.win_platform? ? "mmdc.cmd" : "mmdc"
    [site.source, Dir.pwd].compact.each do |root|
      candidate = File.join(root, "node_modules", ".bin", executable)
      return candidate if File.file?(candidate) && File.executable?(candidate)
    end

    nil
  end
end

Liquid::Template.register_filter(MermaidImageFilter)

Jekyll::Hooks.register :site, :pre_render do |site|
  site.documents.each { |item| MermaidImageFilter.normalize_item_image(item, site) }
  site.pages.each { |item| MermaidImageFilter.normalize_item_image(item, site) }
end
