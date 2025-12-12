namespace :attestations do
  desc "Fix attestations with missing kindVersion or double-encoded certificates (set DRY_RUN=true for dry run)"
  task repair: :environment do
    dry_run = ENV["DRY_RUN"].to_s.downcase.in?(%w[1 true yes])
    mode = dry_run ? "DRY RUN (no changes will be written)" : "LIVE FIX MODE"

    puts "=== Attestation Repair Task ==="
    puts "Mode: #{mode}"
    puts

    batch_size = 1000
    total_count = Attestation.count
    processed = 0
    fixed = 0
    unchanged = 0
    errors = 0

    puts "Total attestations to process: #{total_count}"

    Attestation.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |attestation|
        processed += 1
        body = attestation.body.deep_dup
        needs_fix = false
        changes = []

        begin
          verification = body["verificationMaterial"]

          # -----------------------------
          # 1. Fix missing kindVersion in tlog entries
          # -----------------------------
          if verification && verification["tlogEntries"]
            verification["tlogEntries"].each_with_index do |entry, idx|
              next if entry.key?("kindVersion")
              entry["kindVersion"] = { "kind" => "dsse", "version" => "0.0.1" }
              needs_fix = true
              changes << "Added missing kindVersion to tlogEntry #{idx}"
            end
          end

          # -----------------------------
          # 2. Fix double-encoded certificate rawBytes
          # -----------------------------
          if verification &&
              verification["certificate"] &&
              verification["certificate"]["rawBytes"]

            raw_bytes = verification["certificate"]["rawBytes"]

            begin
              # First layer decode
              decoded_once = Base64.strict_decode64(raw_bytes)

              # Check if decoded_once is PEM → means original was base64(PEM)
              if decoded_once.start_with?("-----BEGIN CERTIFICATE-----")
                cert = OpenSSL::X509::Certificate.new(decoded_once)
                der = cert.to_der
                verification["certificate"]["rawBytes"] = Base64.strict_encode64(der)

                needs_fix = true
                changes << "Converted double-encoded PEM certificate to DER base64"
              end
            rescue ArgumentError, OpenSSL::X509::CertificateError => e
              # ignore invalid certs, but log for visibility
              changes << "Certificate decode error: #{e.message}"
            end
          end

          # -----------------------------
          # Write or skip depending on mode
          # -----------------------------
          if needs_fix
            if dry_run
              puts "[#{processed}/#{total_count}] WOULD FIX Attestation #{attestation.id} — #{changes.join(', ')}"
            else
              attestation.update!(body: body)
              puts "[#{processed}/#{total_count}] FIXED Attestation #{attestation.id} — #{changes.join(', ')}"
              fixed += 1
            end
          else
            unchanged += 1
            puts "[#{processed}/#{total_count}] OK Attestation #{attestation.id} — no issues found"
          end
        rescue StandardError => e
          errors += 1
          puts "[#{processed}/#{total_count}] ERROR Attestation #{attestation.id} — #{e.class}: #{e.message}"
        end
      end

      percent = (processed.to_f / total_count * 100).round(1)
      puts "Batch complete — #{processed}/#{total_count} (#{percent}%) processed"
    end

    # -----------------------------
    # Summary
    # -----------------------------
    puts
    puts "=== Repair Complete ==="
    puts "Mode: #{mode}"
    puts "Total processed: #{processed}"
    puts "Needing fix: #{fixed}"
    puts "Unchanged: #{unchanged}"
    puts "Errors: #{errors}"
  end
end
