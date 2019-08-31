package Giblog::Command::build;

use base 'Giblog::Command';

use strict;
use warnings;

sub run {
  my ($self, @args) = @_;
  
  # API
  my $api = $self->api;
  
  # Read config
  my $config = $api->read_config;
  
  # Copy static files to public
  $api->copy_static_files_to_public;

  # Get files in templates directory
  my $files = $api->get_templates_files;
  
  for my $file (@$files) {
    
    my $data = {file => $file};
    
    # Get content from file in templates directory
    $api->get_content($data);

    # Parse Giblog syntax
    $api->parse_giblog_syntax($data);

    # Parse title
    $api->parse_title_from_first_h_tag($data);

    # Edit title
    my $site_title = $config->{site_title};
    if ($data->{file} eq 'index.html') {
      $data->{title} = $site_title;
    }
    else {
      $data->{title} = "$data->{title} - $site_title";
    }

    # Add page link
    $api->add_page_link_to_first_h_tag($data, {root => 'index.html'});

    # Parse description
    $api->parse_description_from_first_p_tag($data);

    # Get first image src
    $api->parse_first_img_src($data);

    # Read common templates
    $api->read_common_templates($data);
    
    # Add meta title
    $api->add_meta_title($data);

    # Add meta description
    $api->add_meta_description($data);

    # Twitter card
    {
      my $meta = $data->{meta};
      
      my $site_url = $config->{site_url};
      my $title = $data->{title} || '';
      my $description = $data->{description} || '';
      my $img_src = $data->{img_src};
      
      my $twitter_card = <<"EOS";
<meta name="twitter:card" content="summary" />
<meta name="twitter:site" content="\@perlzemi" />
<meta name="twitter:title" content="$title" />
<meta name="twitter:description" content="$description" />
<meta name="twitter:image" content="$site_url/images/giblog-favicon.png" />
EOS
      
      $meta .= "\n$twitter_card\n";
      
      $data->{meta} = $meta;
    }

    # Build entry html
    $api->build_entry($data);
    
    # Build whole html
    $api->build_html($data);
    
    # Write to public file
    $api->write_to_public_file($data);
  }
}

1;
